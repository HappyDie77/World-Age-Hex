extends Control
class_name ActionSlot

@onready var picture: TextureRect = $Frame/Picture
@onready var frame: Panel = $Frame
@onready var action_name_label: RichTextLabel = $ActionName # Assuming you have a label for the action name

var queue_item: QueueItem = null # The data this slot represents
signal slot_pressed(queue_item) # Signal for when the user clicks to remove it

func set_data(qi: QueueItem):
	# --- ADD THIS DEBUG CHECK ---
	if not is_instance_valid(frame):
		# This will print the error in the console and tell you *where* the bad path is.
		push_error("ActionSlot Node Error: 'frame' is NULL. Check path: $Frame")
		return # Skip the rest of the function to prevent crash
	# ----------------------------
	queue_item = qi
	
	# 1. Set the action picture (assuming you have a 'texture' property on the Action resource)
	# NOTE: You must add @export var texture: Texture to Action.gd
	if qi.action.texture and is_instance_valid(picture):
		picture.texture = qi.action.texture
	
	# 2. Change frame color based on faction
	var faction = qi.unit_node.unit_data.faction
	if faction == CombatManager.Faction.ALLY:
		frame.add_theme_stylebox_override("panel", load("res://Scenes/UI/Styles/action_slot_ally.tres"))
	else:
		frame.add_theme_stylebox_override("panel", load("res://Scenes/UI/Styles/action_slot_enemy.tres"))
	if is_instance_valid(action_name_label): # Safety check
		action_name_label.text = qi.action.name.substr(0, 4)

func _on_gui_input(event: InputEvent):
	# Check for a mouse click on the slot itself
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		slot_pressed.emit(queue_item) # Signal back to the CombatManager
