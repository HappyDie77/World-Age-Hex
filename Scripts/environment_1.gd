extends Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

var tween = create_tween()

var is_currently_day = true

func _process(delta):
	if TimeManager.is_daytime(Global.current_minutes) and !is_currently_day:
		# switch to day lighting
		start_day_tween()
		is_currently_day = true
	elif TimeManager.is_nighttime(Global.current_minutes) and is_currently_day:
		# switch to night lighting
		start_night_tween()
		is_currently_day = false

func start_day_tween():
	var tween = create_tween()
	tween.tween_property(directional_light_3d, "light_color", Color("#f4dfa2"), 2.0)
	tween.tween_property(directional_light_3d, "light_energy", 0.6, 2.0)
	tween.tween_property(world_environment.environment, "ambient_light_color", Color(0.996, 0.957, 0.886, 1.0), 2.0)
	tween.tween_property(world_environment.environment, "ambient_light_energy", 1.0, 2.0)
	tween.tween_property(world_environment.environment, "volumetric_fog_emission", Color(1.0, 0.969, 0.533, 1.0), 2.0)
	tween.tween_property(world_environment.environment, "volumetric_fog_albedo", Color(0.541, 0.455, 0.18, 1.0), 2.0)
	tween.tween_property(world_environment.environment, "volumetric_fog_density", 0.02, 3.0)

func start_night_tween():
	var tween = create_tween()
	tween.tween_property(directional_light_3d, "light_color", Color("365ddbff"), 2.0)
	tween.tween_property(directional_light_3d, "light_energy", 0.8, 2.0)
	tween.tween_property(world_environment.environment, "ambient_light_color", Color(0.2, 0.3, 0.5), 2.0)
	tween.tween_property(world_environment.environment, "ambient_light_energy", 0.3, 2.0)
	tween.tween_property(world_environment.environment, "volumetric_fog_emission", Color(0.172, 0.155, 0.0, 1.0), 2.0)
	tween.tween_property(world_environment.environment, "volumetric_fog_albedo", Color(0.084, 0.076, 0.0, 1.0), 2.0)
	tween.tween_property(world_environment.environment, "volumetric_fog_density", 0.04, 3.0)
