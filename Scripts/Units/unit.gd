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
var attacks: Array = []
var defensives: Array = []
var skills: Array = []

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


# 4. Turn Start Event
func on_turn_start(referee: CombatManager):
	for action in attacks + defensives + skills:
		if action.current_cooldown > 0:
			action.current_cooldown -= 1
	# Rule: Apply DOT damage, reduce cooldowns, check expired statuses
	# Example: Check status list for Burn/Poison and call take_damage()
	# Example: current_cooldown -= 1 for all skills
	# Reduce all action cooldowns
	pass
	

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
		# Example: Damage reduction based on Defense stat
		var reduction_factor = 1.0 - (float(target_unit_data.defense) * 0.05)
		raw_damage *= max(0.0, reduction_factor)
		
	return int(raw_damage)
