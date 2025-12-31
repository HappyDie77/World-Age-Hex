extends RefCounted
class_name Unit

# Identity
var name: String
var faction

# Core stats (base values)
var vitality: int
var strength: int
var intelligence: int
var defence: int
var agility: int

# Runtime state
var max_hp: int
var current_hp: int
var alive: bool = true

# Actions lists - now they live here!
var attacks: Array[Action] = []
var defensives: Array[Action] = []
var skills: Array[Action] = []

# --- NEW: STATUS AND BUFF MANAGEMENT ---
# The Array structure to hold active effects.
var active_statuses: Array = [] # Stores dictionary: {name: String, amount: int, duration: int, applied_by: Unit}

# The Unit is initialized using the UnitTemplate Resource
func setup_from_template(template: UnitTemplate) -> void:
	# 1. Copy Template Data (Base Stats/Identity)
	name = template.unit_name
	faction = template.faction_type
	vitality = template.vitality
	strength = template.strength
	intelligence = template.intelligence
	defence = template.defence # Note: Renamed defense to match template export
	agility = template.agility

	# 2. Initialize Runtime State
	_recalculate_max_hp()
	current_hp = max_hp
	
	# 3. Clone Actions from Template
	_clone_actions(template.default_attacks, attacks)
	_clone_actions(template.default_defensives, defensives)
	_clone_actions(template.default_skills, skills)

# Helper function to clone resources
func _clone_actions(template_array: Array, target_array: Array):
	for action_template in template_array:
		# CRITICAL: .duplicate(true) creates a unique copy in memory.
		var cloned_action = action_template.duplicate(true)
		cloned_action.owner = self # Link the action back to this Unit instance
		target_array.append(cloned_action)

# --- Existing Unit Logic ---
func _recalculate_max_hp() -> void:
	max_hp = vitality * 2

func take_damage(amount: int) -> void:
	if not alive:
		return
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		alive = false

func heal(amount: int) -> void:
	if not alive:
		return
	current_hp = min(current_hp + amount, max_hp)
	print(name, " healed for ", amount, ". Current HP: ", current_hp)

# Function called by ActionEffect for DoT/Buffs
func add_status_effect(status_name: String, amount: int, duration: int, source_unit: Unit = null) -> void:
	# Check if status already exists to refresh duration or stack.
	# For simplicity, we'll just add it for now.
	var new_status = {
		"name": status_name, 
		"amount": amount, 
		"duration": duration, 
		"source": source_unit
	}
	active_statuses.append(new_status)

# Function called by ActionEffect for temporary stat changes
func apply_temporary_buff(stat_key: String, amount: int, duration: int) -> void:
	# This function would track the buff internally, but for now, we'll just print.
	print(name, " received a temporary buff: +", amount, " ", stat_key, " for ", duration, " turns.")
	# For a real implementation, you would:
	# 1. Add this buff to a tracking list (like active_statuses).
	# 2. Modify the base stat (e.g., self.strength += amount).
	# 3. Use on_turn_start to reduce the buff's duration and remove it when duration hits 0.

func get_is_dead() -> bool:
	return current_hp <= 0

# --- CORE COMBAT INTEGRATION ---

# 1. Calculate Clash Power (Hard Rule Enforcement)
func get_clash_power(action: Action) -> float:
	var base_power = action.power
	var stat_contribution: float = 0.0
	
	match action.scaling:
		Action.ScalingType.PHYSICAL:
			stat_contribution = float(strength)
		Action.ScalingType.MAGICAL:
			# Example: Power * [1 + (Intelligence / 100)]
			stat_contribution = action.power * (1.0 + float(intelligence) / 100.0)
		# Elemental scaling goes here...
		
	# NOTE: Passive/Card bonuses are calculated here by checking internal lists!
	var flat_bonuses = _calculate_passive_bonuses("clash_power", action)
	
	return base_power + stat_contribution + flat_bonuses


# 2. Execute Offensive Action (Damage/Effects)
func execute_offensive(action: Action, outcome: CombatManager.ClashOutcome, target_unit_data: Unit):
	print(" -> Attacker ", name, " resolves with outcome: ", CombatManager.ClashOutcome.keys()[outcome])

	# --- ACTION LOGIC (Check for effects) ---
	# The action's specific logic (using the ActionEffect resource) determines if it fires
	if action.effect_logic:
		var outcome_string = CombatManager.ClashOutcome.keys()[outcome]
		if action.effect_logic.check_condition(self, target_unit_data, outcome_string):
			action.effect_logic.apply_effect(self, target_unit_data)
			
	# --- DAMAGE LOGIC (Simple Example) ---
	if outcome == CombatManager.ClashOutcome.WIN or outcome == CombatManager.ClashOutcome.FREE_HIT:
		var damage_amount = _calculate_damage_to_target(action, target_unit_data)
		target_unit_data.take_damage(damage_amount)
	
	# --- UNIT PASSIVE TIMINGS (e.g., On Clash Win) ---
	_execute_passive_timing("OnClashWin", action, target_unit_data, outcome)


# 3. Execute Defensive Action
func execute_defensive(defensive_action: Action, offensive_action: Action, outcome: CombatManager.ClashOutcome, attacker_unit_data: Unit):
	print(" -> Defender ", name, " resolves defensive action: ", defensive_action.name)
	
	# Logic for GUARD, COUNTER, REDIRECT goes here.
	match defensive_action.defensive_type:
		Action.DefensiveType.GUARD:
			# Example: Reduce damage from the offensive action
			pass 
		Action.DefensiveType.COUNTER:
			# Example: Trigger a counter-attack if clash is won
			pass 
	
	# --- UNIT PASSIVE TIMINGS (e.g., On Intercept) ---
	_execute_passive_timing("OnIntercept", defensive_action, attacker_unit_data, outcome)


# --- MODIFICATION TO on_turn_start ---
# This is CRITICAL for DoT/Buffs to function.

func on_turn_start(referee: CombatManager):
	# 1. Reduce all action cooldowns
	for action in attacks + defensives + skills:
		if action.current_cooldown > 0:
			action.current_cooldown -= 1
			
	# 2. Process Status Effects (Damage Over Time)
	var statuses_to_remove = []
	for status in active_statuses:
		if status.name == "Burn" or status.name == "Poison":
			# Apply damage
			print(name, " takes ", status.amount, " damage from ", status.name, ".")
			take_damage(status.amount) 
			
		# Reduce duration
		status.duration -= 1
		if status.duration <= 0:
			statuses_to_remove.append(status)

	# 3. Cleanup expired statuses
	for status in statuses_to_remove:
		active_statuses.erase(status)
		print(name, ": Status ", status.name, " expired.")

	# Rule: Check expired statuses / buffs and remove them
	pass # Keep the original pass line if you add more logic later
	

# --- INTERNAL HELPER FUNCTIONS ---
# This is where all the complex synergy and card logic is housed.
func _calculate_passive_bonuses(timing_key: String, action: Action = null) -> float:
	# Example: Check the unit's passive list and card list for bonuses matching 'clash_power'
	# if passive.timing == timing_key: return passive.value
	return 0.0

func _execute_passive_timing(timing_key: String, action, target, outcome):
	# Iterates through all unit passives and card effects to see if they should fire.
	# This keeps the CombatManager clean.
	pass

func _calculate_damage_to_target(action: Action, target_unit_data: Unit) -> int:
	# Full damage formula implementation goes here, including defense mitigation
	var raw_damage = get_clash_power(action) # Use clash power as raw damage base
	
	if action.scaling == Action.ScalingType.PHYSICAL:
		# FIX: Use 'defence' to match the Unit property
		var reduction_factor = 1.0 - (float(target_unit_data.defence) * 0.05) 
		raw_damage *= max(0.0, reduction_factor)
		
	return int(raw_damage)
