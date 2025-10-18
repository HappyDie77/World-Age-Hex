extends Node3D



func _ready() -> void:
	Global.current_energy = Global.max_energy
	Global.current_minutes = 360

func energy_time_cost(energy: int, minutes: int) -> void:
	if Global.current_energy <= 0:
		return

	Global.current_energy -= energy
	Global.current_minutes += minutes

	while Global.current_minutes >= Global.time_max:
		Global.current_minutes -= Global.time_max
		Global.current_day += 1

func is_nighttime(minutes: int) -> bool:
	return minutes >= 1080 or minutes < 360

func is_daytime(minutes: int) -> bool:
	return minutes >= 360 and minutes < 1080
#if is_daytime(Global.current_minutes):
	#print("Daytime logic here")

func minutes_to_hours(minutes: int) -> String:
	var hours = int(minutes / 60)
	var mins = int(minutes % 60)
	return "%02d:%02d" % [hours, mins]
