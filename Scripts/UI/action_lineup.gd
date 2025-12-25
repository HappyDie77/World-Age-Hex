# action_queue_ui.gd (Attach to the HBoxContainer or its parent Control node)

extends Control
class_name ActionQueueDisplay

const ACTION_SLOT_SCENE = preload("res://Scenes/UI/action_slot.tscn")

# Signal to pass the removal request up to the CombatManager
signal remove_action_requested(queue_item) 

@onready var container: HBoxContainer = $HBoxContainer # Assuming your container is named HBoxContainer

func update_queue_display(queue_items: Array[QueueItem]):
	# 1. Clear previous items
	for child in container.get_children():
		child.queue_free()

	# 2. Re-create the visual elements
	for qi in queue_items:
		var action_slot: ActionSlot = ACTION_SLOT_SCENE.instantiate()
		
		# Verify the script is attached and the class_name is being used
		if action_slot is ActionSlot:
			action_slot.set_data(qi)
			
			# Connect the slot's press signal to a local handler
			action_slot.slot_pressed.connect(_on_action_slot_pressed)
			
			container.add_child(action_slot)
		else:
			# This handles cases where the script isn't attached to the root of the scene
			push_error("ActionSlot scene did not instantiate as ActionSlot class!")

func _on_action_slot_pressed(queue_item_to_remove: QueueItem):
	# Pass the request up to the CombatManager to handle the queue modification
	remove_action_requested.emit(queue_item_to_remove)
