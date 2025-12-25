extends Node3D

const COMBAT_HUD = preload("uid://c8wy6x6cfpoww")
var combat_manager: Node


@onready var spring_arm_3d: SpringArm3D = $SpringArm3D
@onready var main_camera: Camera3D = $"SpringArm3D/Main Camera"
@onready var ray_cast_3d: RayCast3D = $"SpringArm3D/Main Camera/RayCast3D"
@onready var camera_light: OmniLight3D = $"SpringArm3D/Camera light"
@onready var camera_light_2: SpotLight3D = $"SpringArm3D/Camera light2"

@export var zoom_speed: float = 0.8
@export var min_zoom: float = 5
@export var max_zoom: float = 5
@export var zoom_smoothness: float = 6.0  # Higher = smoother
@export var mouse_offset_strength: float = 0.08
@export var mouse_smoothness: float = 8.0
@export var max_rotation: float = 0.12
@export var base_pitch: float = -0.5  # ≈ 25 degrees downward

var target_rotation := Vector2.ZERO

var target_zoom: float
var last_selected: Node3D = null
var is_currently_day = true

func _ready() -> void:
	combat_manager = $"../CombatManager"
	target_zoom = 5

func _physics_process(delta: float) -> void:
	# Zoom smoothing
	spring_arm_3d.spring_length = lerp(
		spring_arm_3d.spring_length,
		target_zoom,
		delta * zoom_smoothness
	)

	_update_mouse_camera(delta)

func _update_mouse_camera(delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var mouse_pos := get_viewport().get_mouse_position()

	# Normalize mouse position (-1 to 1)
	var normalized := (mouse_pos / viewport_size) * 2.0 - Vector2.ONE

	# Dead zone
	if normalized.length() < 0.1:
		normalized = Vector2.ZERO

	# Mouse sway offsets
	var pitch_offset := -normalized.y * mouse_offset_strength
	var yaw_offset := -normalized.x * mouse_offset_strength

	# Clamp offsets
	pitch_offset = clamp(pitch_offset, -max_rotation, max_rotation)
	yaw_offset = clamp(yaw_offset, -max_rotation, max_rotation)

	# Apply BASE + OFFSET
	spring_arm_3d.rotation.x = lerp(
		spring_arm_3d.rotation.x,
		base_pitch + pitch_offset,
		delta * mouse_smoothness
	)

	spring_arm_3d.rotation.y = lerp(
		spring_arm_3d.rotation.y,
		yaw_offset,
		delta * mouse_smoothness
	)


func start_day_tween():
	camera_light.visible = false # in start_day_tween()
	camera_light_2.visible = false

func start_night_tween():
	camera_light.visible = true  # in start_night_tween()
	camera_light_2.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Mouse wheel up (zoom in)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom = max(min_zoom, target_zoom - zoom_speed)
		# Mouse wheel down (zoom out)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom = min(max_zoom, target_zoom + zoom_speed)

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selection()


func selection():
	# UI guard
	if get_viewport().gui_get_hovered_control():
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = main_camera.project_ray_origin(mouse_pos)
	var to = from + main_camera.project_ray_normal(mouse_pos) * 1000.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		combat_manager.clear_selection()
		return

	var node: Node = result.collider
	while node and not node is UnitNode:
		node = node.get_parent()

	if node:
		node.on_clicked()
	else:
		combat_manager.clear_selection()
