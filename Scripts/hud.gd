extends Control

@onready var time: Label = $Hud/Time
@onready var energy: Label = $Hud/Energy

@onready var move_1_hex: Button = $"Hud/Buttons/Move 1 Hex"
@onready var combat_encounter: Button = $"Hud/Buttons/Combat encounter"
@onready var event: Button = $Hud/Buttons/Event
@onready var rest: Button = $Hud/Buttons/Rest
@onready var sleep: Button = $Hud/Buttons/Sleep

func _ready() -> void:
	time.text = TimeManager.minutes_to_hours(Global.current_minutes)
	energy.text = str(Global.current_energy)

func _on_move_1_hex_pressed() -> void:
	TimeManager.energy_time_cost(1, 65)
	time.text = TimeManager.minutes_to_hours(Global.current_minutes)
	energy.text = str(Global.current_energy)

func _on_combat_encounter_pressed() -> void:
	pass # Replace with function body.

func _on_event_pressed() -> void:
	pass # Replace with function body.

func _on_rest_pressed() -> void:
	pass # Replace with function body.

func _on_sleep_pressed() -> void:
	pass # Replace with function body.
