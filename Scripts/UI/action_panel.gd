extends Panel

signal action_selected(action: Action)

@onready var attacks_box = $TabContainer/Attacks/ScrollContainer/VBoxContainer
@onready var defensives_box = $TabContainer/Defensives/ScrollContainer/VBoxContainer
@onready var skills_box = $TabContainer/Skills/ScrollContainer/VBoxContainer
@onready var tab_container: TabContainer = $TabContainer

func clear():
	for box in [attacks_box, defensives_box, skills_box]:
		for child in box.get_children():
			child.queue_free()

func show_actions(attacks: Array, defensives: Array, skills: Array):
	clear()

	_create_buttons(attacks, attacks_box)
	_create_buttons(defensives, defensives_box)
	_create_buttons(skills, skills_box)

func _create_buttons(actions: Array, container: VBoxContainer):
	for action in actions:
		var btn := Button.new()
		btn.text = action.name
		# This line emits the signal, passing the Action resource object.
		btn.pressed.connect(func(): emit_signal("action_selected", action)) 
		container.add_child(btn)
