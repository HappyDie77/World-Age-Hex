extends Node3D

@onready var spring_arm_3d: SpringArm3D = $SpringArm3D
@onready var main_camera: Camera3D = $"SpringArm3D/Main Camera"
@onready var ray_cast_3d: RayCast3D = $"SpringArm3D/Main Camera/RayCast3D"

@export var zoom_speed: float = 1.0
@export var min_zoom: float = 3.0
@export var max_zoom: float = 8.0
@export var zoom_smoothness: float = 6.0  # Higher = smoother
@export var move_speed: float = 5.0
@export var sprint_multiplier: float = 2.0

var target_zoom: float
var last_selected: Node3D = null

func _ready() -> void:
	target_zoom = 6

func _physics_process(delta: float) -> void:
	spring_arm_3d.spring_length = lerp(spring_arm_3d.spring_length, target_zoom, delta * zoom_smoothness)
	
	var move_dir = Vector3.ZERO
	if Input.is_action_pressed("w"):
		move_dir.z -= 1
	if Input.is_action_pressed("a"):
		move_dir.x -= 1
	if Input.is_action_pressed("s"):
		move_dir.z += 1
	if Input.is_action_pressed("d"):
		move_dir.x += 1
	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized()
		var speed = move_speed
		if Input.is_action_pressed("shift"):
			speed *= sprint_multiplier
		translate_object_local(move_dir * speed * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Mouse wheel up (zoom in)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom = max(min_zoom, target_zoom - zoom_speed)
		# Mouse wheel down (zoom out)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom = min(max_zoom, target_zoom + zoom_speed)

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("pressed")
			hex_movement()


func hex_movement():
	if not main_camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = main_camera.project_ray_origin(mouse_pos)
	var to = from + main_camera.project_ray_normal(mouse_pos) * 1000.0
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 1  # Make sure your tiles/objects use this layer
	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		var target = collider.get_parent().get_parent()

		# Change highlight if we hit a new object
		if target:
			print("hit")
			# Turn off old selector
			if last_selected and last_selected.has_method("highlight"):
				last_selected.highlight(false)

			# Turn on new one
			if target and target.has_method("highlight"):
				target.highlight(true)

			last_selected = target

	else:
		# If no hit, remove highlight from the previous one
		if last_selected and last_selected.has_method("highlight"):
			last_selected.highlight(false)
		last_selected = null
