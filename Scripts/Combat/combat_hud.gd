extends Control
class_name CombatHUD

@onready var turn: Label = $Hud/Turn
@onready var turn_side: Label = $Hud/Turn_Side
@onready var end_turn: Button = $"Hud/Buttons/End Turn"

@onready var unit_panel: Panel = $"Hud/Unit Panel"
@onready var name_label: Label = $"Hud/Unit Panel/VBoxContainer/Name"
@onready var hp_bar: ProgressBar = $"Hud/Unit Panel/VBoxContainer/HPBar"
@onready var hp_label: Label = $"Hud/Unit Panel/VBoxContainer/HPBar/HPLabel"

@onready var vitality: Label = $"Hud/Unit Panel/VBoxContainer/Stats/Vitality"
@onready var armor: Label = $"Hud/Unit Panel/VBoxContainer/Stats/Armor"
@onready var strength: Label = $"Hud/Unit Panel/VBoxContainer/Stats/Strength"
@onready var intelligence: Label = $"Hud/Unit Panel/VBoxContainer/Stats/Intelligence"
@onready var agility: Label = $"Hud/Unit Panel/VBoxContainer/Stats/Agility"

@onready var action_panel: Panel = $"Hud/Action Panel"

var selected_unit = null
var selected_action = null

signal action_selected(action: Action) # Use the same name as the panel for clarity, but the manager MUST listen to the HUD's signal.

func show_unit(unit: Unit, attacks: Array, defensives: Array, skills: Array):
	if not unit:
		unit_panel.visible = false
		action_panel.visible = false
		return
	
	unit_panel.visible = true
	action_panel.visible = true

	name_label.text = unit.name
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp
	hp_label.text = "%d / %d" % [unit.current_hp, unit.max_hp]

	# Update stats
	vitality.text = str("Vitality ", unit.vitality)
	armor.text = str("Armor ", unit.defence)
	strength.text = str("Strength ", unit.strength)
	intelligence.text = str("Intelligence ", unit.intelligence)
	agility.text = str("Agility ", unit.agility)

	# Display actions dynamically
	action_panel.show_actions(attacks, defensives, skills)


# This is the function the CombatManager is trying to call.
# It needs to accept the arguments passed by the CombatManager:
func update_ui(turn_number: int, action_pool: int, current_faction):
	# --- Required Code: Placeholder to stop the error ---
	print("HUD Update: Turn ", turn_number, ", AP: ", action_pool, ", Faction: ", current_faction)

	# --- Actual Logic (What you need to implement later) ---
	
	# Example: Update a Label for the turn number
	# $TurnLabel.text = "Turn: " + str(turn_number)
	
	# Example: Update a Label for the action pool
	# $APLabel.text = "AP: " + str(action_pool)
	
	# Example: If your HUD changes appearance based on the active faction
	# if current_faction == CombatManager.Faction.ALLY:
	#     $PlayerBorder.show()
	# else:
	#     $EnemyBorder.show()
	
	pass # Keep the 'pass' or add your UI update logic

func _on_action_pressed(action):
	selected_action = action
	print("Selected action:", action.name)

func _on_action_selected(action: Action):
	emit_signal("action_selected", action)
	selected_action = action
	print("Selected action:", action.name)

func _ready() -> void:
	action_panel.action_selected.connect(_on_action_selected)
	action_panel.visible = false
	unit_panel.visible = false
	Global.turn_count = 1
	turn.text = str("Turn ", Global.turn_count)

	if Global.player_turn:
		turn_side.text = str("Your Turn")
	else:
		turn_side.text = str("Enemy Turn")

func _process(delta: float) -> void:
	if Global.player_turn:
		turn_side.text = str("Your Turn")
	else:
		turn_side.text = str("Enemy Turn")

func _on_end_turn_pressed() -> void:
	Global.turn_count += 1
	Global.player_end = true
	turn.text = str("Turn ", Global.turn_count)

func _on_color_rect_mouse_entered() -> void:
	Global.actions_entered = true

func _on_color_rect_mouse_exited() -> void:
	Global.actions_entered = false
