extends Unit

# --- Action Types ---
enum ActionType { ATTACK, DEFENSE, SKILL }

# --- Unit-specific Actions ---
class UnitAction:
	var name: String
	var power: int
	var category: int
	var damage_type: String = "Physical"
	var cooldown: int = 0

	func _init(_name: String, _power: int, _category: int, _damage_type: String = "Physical", _cooldown: int = 0):
		name = _name
		power = _power
		category = _category
		damage_type = _damage_type
		cooldown = _cooldown

var actions: Array = []
var selected_target: Node = null

# Signals
signal action_selected(action, target)

# Select an action and target
func select_action(action_index: int, target: Node) -> void:
	if action_index < 0 or action_index >= actions.size():
		return
	var action = actions[action_index]
	selected_target = target
	emit_signal("action_selected", action, target)
	print(name, "selected action:", action.name, "on", target.name)

# Create example actions for this unit
func create_example_actions() -> void:
	actions = [
		UnitAction.new("Slash", 5, ActionType.ATTACK, "Physical"),
		UnitAction.new("Guard", 3, ActionType.DEFENSE, "Physical"),
		UnitAction.new("Fireball", 7, ActionType.SKILL, "Magical")
	]
