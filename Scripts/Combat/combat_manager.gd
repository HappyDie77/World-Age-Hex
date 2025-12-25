# CombatManager.gd
extends Node3D
class_name CombatManager

# --- SCENE AND TEMPLATE RESOURCES ---
const UNIT_NODE_SCENE = preload("uid://b0sm6ksjayflx") 
const TEMPLATE_FACTION_MAPPING: Dictionary = {
	Faction.ALLY: preload("res://Scripts/Units/Units Resources/Test_Unit.tres"), # Example
	Faction.ENEMY: preload("res://Scripts/Units/Units Resources/Test_Unit_Enemy.tres")  # Example
}

# --- @ONREADY SLOTS ---
@onready var unit_slots: Array[Node3D] = [
	$"../unit_zones/unit_1", $"../unit_zones/unit_2", $"../unit_zones/unit_3"
]
@onready var enemy_slots: Array[Node3D] = [
	$"../enemy_zones/enemy_1", $"../enemy_zones/enemy_2", $"../enemy_zones/enemy_3"
]

# --- UI Reference ---
@onready var action_queue_ui: Control = get_tree().get_first_node_in_group("action_queue_display")
# NOTE: Ensure you have a Control node in the group "action_queue_display"

# --- ENMUS ---
enum Faction { ALLY, ENEMY } # Defines who is who (Rule)
enum ClashOutcome { WIN, LOSE, TIE, FREE_HIT } # Defines the result of an engagement (Rule)

# --- COMBAT STATE ---
var all_unit_nodes: Array[UnitNode] = []
var active_units: Array[UnitNode] = [] # Units currently alive
var action_queue: Array[QueueItem] = []
var action_pool: int = 2 # Shared action points for the player

# --- TURN STATE ---
var turn_number: int = 0
var player_planning_phase: bool = false
var selected_unit_node: UnitNode = null
var combat_hud: Control = null

# ==============================================================================
# 1. SETUP AND INITIALIZATION
# ==============================================================================

func _ready() -> void:
	combat_hud = get_tree().get_first_node_in_group("combat_hud")
	
	# --- CRITICAL CONNECTION STEP ---
	if combat_hud:
		# Connect the correct signal name: 'action_selected'
		combat_hud.action_selected.connect(_on_action_selected_from_hud) 
		
		# Link the UI's removal request to the Combat Manager's logic (Moved this from the bottom)
		action_queue_ui.remove_action_requested.connect(_on_remove_action_requested)
	else:
		push_error("Combat HUD not found in 'combat_hud' group. Cannot connect signals.")
	
	# Placeholder: In a real game, this data comes from PlayerData/Global
	var player_selection = [TEMPLATE_FACTION_MAPPING[Faction.ALLY].duplicate(), TEMPLATE_FACTION_MAPPING[Faction.ALLY].duplicate(), TEMPLATE_FACTION_MAPPING[Faction.ALLY].duplicate()]
	var enemy_selection = [TEMPLATE_FACTION_MAPPING[Faction.ENEMY].duplicate(), TEMPLATE_FACTION_MAPPING[Faction.ENEMY].duplicate(), TEMPLATE_FACTION_MAPPING[Faction.ENEMY].duplicate()]
	
	_initialize_battlefield(player_selection, enemy_selection)
	start_turn()
	
	# Link the UI's removal request to the Combat Manager's logic
	action_queue_ui.remove_action_requested.connect(_on_remove_action_requested)

func _on_remove_action_requested(qi_to_remove: QueueItem):
	# Only allow player actions to be removed during planning phase
	if not player_planning_phase or qi_to_remove.unit_node.unit_data.faction == Faction.ENEMY:
		return
		
	_remove_action_from_queue(qi_to_remove)


func _remove_action_from_queue(qi_to_remove: QueueItem):
	var index = action_queue.find(qi_to_remove)
	if index != -1:
		# 1. Refund cost
		action_pool += qi_to_remove.cost
		combat_hud.update_ui(turn_number, action_pool, Faction.ALLY)
		
		# 2. Remove the action
		action_queue.remove_at(index)
		
		# 3. Update the UI to show the shift
		_update_action_queue_display()
		
		print("Action removed: ", qi_to_remove.action.name)

# Creates Unit data and UnitNode instances
func _initialize_battlefield(player_templates: Array, enemy_templates: Array) -> void:
	# Spawn Allies
	_spawn_units(player_templates, unit_slots)
	# Spawn Enemies
	_spawn_units(enemy_templates, enemy_slots)
	
	active_units = all_unit_nodes.duplicate()
	print("Combat ready. Total Units: ", active_units.size())


func _spawn_units(templates: Array, slots: Array):
	for i in range(min(templates.size(), slots.size())):
		var template: UnitTemplate = templates[i] as UnitTemplate
		if not template: continue
		
		# 1. Create Unit Data instance
		var unit_data = Unit.new()
		unit_data.setup_from_template(template)

		# 2. Create Unit Node (3D scene instance)
		var unit_node: UnitNode = UNIT_NODE_SCENE.instantiate()
		slots[i].add_child(unit_node)
		unit_node.position = Vector3.ZERO
		
		# 3. Link Data to Node and Register
		unit_node.setup(unit_data) 
		unit_node.selected.connect(_on_unit_selected)
		
		all_unit_nodes.append(unit_node)


# ==============================================================================
# 2. TURN MANAGEMENT
# ==============================================================================

func start_turn():
	turn_number += 1
	action_pool = min(action_pool + 1, 10) # Simple rule: +1 action, max 10
	action_queue.clear()
	
	# --- Execute Turn Start Effects (Rule Enforcement) ---
	for unit in active_units:
		# The Unit's data handles its own effects (e.g., DOT ticks, passive cooldowns)
		unit.unit_data.on_turn_start(self) # Referee calls Unit's method
		
	player_planning_phase = true
	combat_hud.update_ui(turn_number, action_pool, Faction.ALLY)
	print("\n--- TURN ", turn_number, ": Player Planning Phase ---")

func end_player_turn():
	if not player_planning_phase: return
	player_planning_phase = false
	
	# 1. Add Enemy Actions to Queue
	_plan_enemy_actions()
	_update_action_queue_display() # <--- CALL HERE
	
	# 2. Resolve Combat
	_resolve_action_queue()
	
	# 3. Cleanup and Next Turn
	_end_turn_cleanup()
	start_turn()


# ==============================================================================
# 3. ACTION PLANNING (Targeting & Queueing)
# ==============================================================================

func _plan_enemy_actions():
	print("--- ENEMY PLANNING ---")
	var enemy_units = active_units.filter(func(u): return u.unit_data.faction == Faction.ENEMY)
	var player_units = active_units.filter(func(u): return u.unit_data.faction == Faction.ALLY)

	if player_units.is_empty(): 
		return # No targets left

	for enemy in enemy_units:
		var enemy_data = enemy.unit_data
		if enemy_data.is_dead: continue
		
		# --- 1. Filter Available Offensive Actions ---
		var available_attacks = enemy_data.attacks.filter(func(a): return a.current_cooldown <= 0)
		var available_skills = enemy_data.skills.filter(func(s): return s.current_cooldown <= 0)
		
		var all_offensive_actions: Array[Action] = available_attacks + available_skills
		
		if all_offensive_actions.is_empty():
			print("Enemy ", enemy_data.name, " has no actions available.")
			continue

		# --- 2. Action Selection (Simple Random AI) ---
		var chosen_action: Action = all_offensive_actions.pick_random()
		var target_node: UnitNode = player_units.pick_random() # Target a random player unit

		if chosen_action and target_node:
			# Enemy costs are often fixed or ignored for simple AI
			queue_action(enemy, chosen_action, target_node, 0) 
			
			# --- 3. Immediate Cooldown Activation (Optional but good practice) ---
			# NOTE: We operate on the CLONED action in the queue, but setting it on 
			# the UNIT's array is safer for persistent cooldowns.
			
			# We must find the ORIGINAL action object on the unit to set its cooldown
			var original_action = enemy_data.attacks.find(chosen_action)
			if original_action:
				original_action.current_cooldown = chosen_action.cooldown_max
			else:
				# Check skills list if it wasn't an attack
				original_action = enemy_data.skills.find(chosen_action)
				if original_action:
					original_action.current_cooldown = chosen_action.cooldown_max
			
			print("Enemy ", enemy_data.name, " queues ", chosen_action.name, 
				  " on ", target_node.unit_data.name, 
				  ". CD set to ", chosen_action.cooldown_max)

func _update_action_queue_display():
	if action_queue_ui:
		# Pass the queue items to the HUD script for rendering
		action_queue_ui.update_queue_display(action_queue)
	
	# Optional console log for verification
	var log_string = "Queue: ["
	for qi in action_queue:
		log_string += qi.unit_node.unit_data.name + " (" + qi.action.name + "), "
	log_string += "]"
	print(log_string)

func queue_action(unit_node: UnitNode, action_template: Action, target_node: UnitNode, cost: int) -> bool:
	if action_pool < cost and unit_node.unit_data.faction == Faction.ALLY:
		print("Not enough action points.")
		return false
	var qi = QueueItem.new()
	qi.unit_node = unit_node
	
	# CRITICAL: Duplicate the action template before queueing, so cooldowns/state are unique
	qi.action = action_template.duplicate(true)
	qi.action.owner = unit_node.unit_data # Link cloned action back to unit data
	
	qi.target_node = target_node
	qi.cost = cost
	
	action_queue.append(qi)
	
	if unit_node.unit_data.faction == Faction.ALLY:
		action_pool -= cost
		combat_hud.update_ui(turn_number, action_pool, Faction.ALLY)
		
	_update_action_queue_display() # <--- CALL HERE
	
	return true


# ==============================================================================
# 4. ACTION RESOLUTION (The Core Referee Logic)
# ==============================================================================

func _resolve_action_queue():
	print("\n--- RESOLUTION PHASE ---")
	
	# Sort the queue by its index (Action 1, Action 2, etc.) - it's already sorted by append order
	
	for i in range(action_queue.size()):
		var qi: QueueItem = action_queue[i]
		
		# Check for canceled actions (e.g., unit died before action)
		if qi.unit_node.unit_data.is_dead or not qi.action:
			continue
			
		print("\nResolving Action ", i + 1, ": ", qi.action.name, " by ", qi.unit_node.unit_data.name)
		
		# 1. Find a Defensive Interceptor (Priority 1)
		var interceptor_qi: QueueItem = _find_interceptor(qi, i + 1)
		
		var target_node = interceptor_qi.unit_node if interceptor_qi else qi.target_node
		var target_unit_data = target_node.unit_data
		
		# 2. Clash Logic (Rule Enforcement)
		var clash_outcome: ClashOutcome
		
		# Determine opponent action: Can be another attack, a skill, or the interceptor's action
		var opponent_qi: QueueItem = _find_opponent_action(qi, interceptor_qi, i + 1)

		if opponent_qi:
			# If an opponent action is found (either attack or defensive interceptor)
			clash_outcome = _calculate_clash(qi.action, opponent_qi.action)
		else:
			# No opposition means a FREE HIT
			clash_outcome = ClashOutcome.FREE_HIT

		# 3. Apply Effects and Damage (Delegated to Units)
		# The Referee (CombatManager) tells the Attacker and the Defender what happened.

		if interceptor_qi:
			_resolve_defensive_action(interceptor_qi, qi, clash_outcome)
			# The original attack is consumed by the defensive action and may not proceed further
			# depending on the defensive's type (Guard, Counter, Redirect).
			interceptor_qi.action = null # Defensive action consumed

		else:
			# No interceptor, execute Attack/Skill directly
			_resolve_offensive_action(qi, clash_outcome, target_node)
			

func _find_interceptor(offensive_qi: QueueItem, current_index: int) -> QueueItem:
	# Rule: Check all subsequent actions in the queue for unconsumed Defensive actions
	# that can intercept the target of the offensive_qi.
	var target_data = offensive_qi.target_node.unit_data
	
	for j in range(current_index, action_queue.size()):
		var potential_interceptor_qi: QueueItem = action_queue[j]
		var action = potential_interceptor_qi.action
		
		# Check 1: Is it a valid, unconsumed defensive action?
		if action and action.category == Action.Category.DEFENSIVE:
			# Check 2: Does it belong to the target or an ally of the target? (Simple check)
			if potential_interceptor_qi.unit_node.unit_data.faction == target_data.faction:
				print("-> INTERCEPTED by ", potential_interceptor_qi.unit_node.unit_data.name)
				return potential_interceptor_qi
	return null # Free hit


func _find_opponent_action(main_qi: QueueItem, interceptor_qi: QueueItem, current_index: int) -> QueueItem:
	# Priority: 1. Interceptor (if exists), 2. Opposing Attack/Skill later in queue
	
	if interceptor_qi:
		return interceptor_qi

	# Check later actions on the target/opposing team
	# Rule: Find the next action aimed at the attacker by the defender's team
	# (Simplified for clarity: Clash only happens if targeted unit has an action later)
	var main_unit_faction = main_qi.unit_node.unit_data.faction
	
	for j in range(current_index, action_queue.size()):
		var potential_opponent_qi: QueueItem = action_queue[j]
		var opponent_action = potential_opponent_qi.action

		if opponent_action and (opponent_action.category == Action.Category.ATTACK or opponent_action.category == Action.Category.SKILL):
			if potential_opponent_qi.unit_node.unit_data.faction != main_unit_faction:
				# If the opposing team has a pending Attack/Skill, they clash.
				return potential_opponent_qi

	return null


func _calculate_clash(action_a: Action, action_b: Action) -> ClashOutcome:
	# 1. Referee asks the Units for their Clash Power
	var power_a = action_a.owner.get_clash_power(action_a)
	var power_b = action_b.owner.get_clash_power(action_b)
	
	print("   Clash Power A (", action_a.name, "): ", power_a)
	print("   Clash Power B (", action_b.name, "): ", power_b)

	if power_a > power_b:
		return ClashOutcome.WIN
	elif power_a < power_b:
		return ClashOutcome.LOSE
	else:
		# Tiebreaker Rule: Agility Check
		var agi_a = action_a.owner.agility
		var agi_b = action_b.owner.agility
		
		if agi_a > agi_b:
			return ClashOutcome.WIN
		elif agi_a < agi_b:
			return ClashOutcome.LOSE
		else:
			return ClashOutcome.TIE


func _resolve_offensive_action(qi: QueueItem, outcome: ClashOutcome, target_node: UnitNode):
	# Referee tells the Unit to execute its own effects/damage based on the outcome
	qi.unit_node.unit_data.execute_offensive(qi.action, outcome, target_node.unit_data)
	
	# Check for death/cancellation after damage/effects
	_check_death(target_node)


func _resolve_defensive_action(interceptor_qi: QueueItem, offensive_qi: QueueItem, outcome: ClashOutcome):
	# Referee tells the Defensive Unit what attacked it and what the result was
	interceptor_qi.unit_node.unit_data.execute_defensive(
		interceptor_qi.action, 
		offensive_qi.action, 
		outcome, 
		offensive_qi.unit_node.unit_data
	)
	# The defensive action is marked for consumption in the main loop
	

func _check_death(unit_node: UnitNode):
	# Rule Enforcement: Check if HP <= 0
	if unit_node.unit_data.is_dead:
		print("!!! ", unit_node.unit_data.name, " has been defeated. !!!")
		active_units.erase(unit_node)
		
		# Rule: Cancel remaining queued actions
		for qi in action_queue:
			if qi.unit_node == unit_node:
				qi.action = null # Mark for cancellation


# ==============================================================================
# 5. CLEANUP AND UI
# ==============================================================================

func _end_turn_cleanup():
	# Remove consumed/canceled actions
	action_queue = action_queue.filter(func(qi): return qi.action != null)
	
	# Final check for victory/defeat
	var allies_left = active_units.any(func(u): return u.unit_data.faction == Faction.ALLY)
	var enemies_left = active_units.any(func(u): return u.unit_data.faction == Faction.ENEMY)
	
	if not allies_left:
		print("GAME OVER: Defeat.")
	elif not enemies_left:
		print("VICTORY!")
	
	# UI updates / Camera resets, etc.
	clear_selection()

# ==============================================================================
# 6. INPUT AND SELECTION (UI/3D World Interaction)
# ==============================================================================

var planning_action: Action = null   # The action resource selected from the Unit's HUD
var planning_unit_node: UnitNode = null # The unit performing the action

func _on_unit_selected(unit_node: UnitNode):
	if not player_planning_phase: return

	if planning_action:
		# State 2: An action is selected, this click is the TARGET
		
		# Check if the target is valid (e.g., must target enemy if attack)
		if planning_unit_node.unit_data.faction == unit_node.unit_data.faction:
			print("Cannot target friendly unit with this action type.")
			return # Add more complex validation here
			
		# Queue the action with the chosen target
		queue_action(planning_unit_node, planning_action, unit_node, planning_action.cost)
		
		# Reset the planning state immediately after queueing
		reset_planning_state()
		
	else:
		# State 1: No action selected, this click is to select the PERFORMING UNIT
		
		# Deselect previous unit and select new unit
		if selected_unit_node:
			selected_unit_node.highlight(false)
			
		selected_unit_node = unit_node
		selected_unit_node.highlight(true)
		
		var u = selected_unit_node.unit_data
		combat_hud.show_unit(u, u.attacks, u.defensives, u.skills)

func reset_planning_state():
	planning_action = null
	planning_unit_node = null
	# You may want to update the cursor/UI here to show targeting is over

# Helper function to receive action clicks from the HUD
func _on_action_selected_from_hud(action_template: Action):
	if not player_planning_phase or not selected_unit_node:
		print("Cannot select action now.")
		return
		
	# Check Cooldown: Always check the original action on the unit's data!
	if action_template.current_cooldown > 0:
		print("Action is on cooldown.")
		return
		
	if action_template.cost > action_pool:
		print("Not enough AP.")
		return

	# Enter Targeting State (Change cursor/UI feedback here)
	planning_action = action_template
	planning_unit_node = selected_unit_node
	print("Action ", action_template.name, " selected. Choose a target.")

func clear_selection():
	if selected_unit_node:
		selected_unit_node.highlight(false)
		selected_unit_node = null
		combat_hud.show_unit(null, [], [], [])
