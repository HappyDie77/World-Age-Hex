# action_queue_ui.gd
extends Control
class_name ActionQueueDisplay

const ACTION_SLOT_SCENE = preload("res://Scenes/UI/action_slot.tscn")

signal remove_action_requested(queue_item) 

@onready var container: HBoxContainer = $HBoxContainer 

func _ready():
	# SAFETY: Clear any placeholder slots that might be in the editor design
	for child in container.get_children():
		child.queue_free()

func update_queue_display(queue_items: Array[QueueItem]):
	# 1. Clear previous itemsz
	for child in container.get_children():
		child.queue_free()

	# 2. Re-create the visual elements
	for qi in queue_items:
		var action_slot = ACTION_SLOT_SCENE.instantiate()
		
		if action_slot is ActionSlot:
			# Note: We add child first, so @onready vars inside the slot initialize
			container.add_child(action_slot)
			
			# Then we set data
			action_slot.set_data(qi)
			
			# Connect signal
			action_slot.slot_pressed.connect(_on_action_slot_pressed)
		else:
			push_error("ActionSlot scene did not instantiate as ActionSlot class!")
			action_slot.queue_free() # Clean up invalid instance

func _on_action_slot_pressed(queue_item_to_remove: QueueItem):
	remove_action_requested.emit(queue_item_to_remove)
