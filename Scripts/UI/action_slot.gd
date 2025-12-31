extends Control
class_name ActionSlot

@onready var picture: TextureRect = $Frame/Picture
@onready var frame: Panel = $Frame
@onready var action_name_label: RichTextLabel = $ActionName 
@onready var remove_button: Button = $Frame/Remove # Ensure this path is correct

var queue_item: QueueItem = null 
signal slot_pressed(queue_item) 

func set_data(qi: QueueItem):
	# 1. Validation Checks
	if not is_instance_valid(frame):
		push_error("ActionSlot Node Error: 'frame' is NULL. Check path: $Frame")
		return
	if not qi:
		push_error("ActionSlot Error: Received NULL QueueItem")
		return

	# 2. Assign Data
	queue_item = qi
	print("ActionSlot Initialized for:", qi.action.name) # This confirms set_data ran

	# 3. Setup Visuals
	if qi.action.texture and is_instance_valid(picture):
		picture.texture = qi.action.texture
	
# DYNAMIC FONT SIZING
	var name_len = qi.action.name.length()
	var font_size = 14 # Default size (Adjust to your preference)
	
	# If name is long, shrink the font
	if name_len > 8:
		font_size = 10
	if name_len > 12:
		font_size = 8
		
	# Apply the size override
	if is_instance_valid(action_name_label):
		action_name_label.add_theme_font_size_override("normal_font_size", font_size)
		action_name_label.text = "[center]%s[/center]" % qi.action.name

	# 4. Connect Button (Safe Connection)
	if remove_button:
		# Disconnect first to ensure we don't have duplicates or old editor connections
		if remove_button.pressed.is_connected(_on_remove_pressed):
			remove_button.pressed.disconnect(_on_remove_pressed)
		
		# Connect fresh
		remove_button.pressed.connect(_on_remove_pressed)
	else:
		push_error("ActionSlot Error: Remove Button not found at path $Frame/Remove")

func _on_remove_pressed() -> void:
	if queue_item:
		print("Requesting removal of:", queue_item.action.name)
		slot_pressed.emit(queue_item)
	else:
		# This should now be impossible unless a ghost slot exists
		push_error("CRITICAL: Button clicked on an ActionSlot with NO DATA.")
