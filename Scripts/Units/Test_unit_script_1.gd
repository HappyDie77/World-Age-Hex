extends CharacterBody3D
class_name UnitNode

@onready var unit_body: MeshInstance3D = $UnitBody

signal selected(unit_node: UnitNode)

var highlight_mat: StandardMaterial3D
var original_color: Color
var tween: Tween
var unit_data: Unit

func setup(data: Unit) -> void:
	unit_data = data
	# The unit_data object now manages its own actions,
	# which can be loaded from a resource or modified by cards/upgrades.
	# We should, however, ensure the Unit object is fully initialized here.


# Function to get actions, now pulling from the data object
func get_all_actions() -> Dictionary:
	return {
		"attacks": unit_data.attacks,
		"defensives": unit_data.defensives,
		"skills": unit_data.skills
	}

func _ready():
	var base_mat := unit_body.get_surface_override_material(0)
	if not base_mat:
		base_mat = unit_body.mesh.surface_get_material(0)

	highlight_mat = base_mat.duplicate()
	unit_body.set_surface_override_material(0, highlight_mat)
	original_color = highlight_mat.albedo_color

func on_clicked():
	emit_signal("selected", self)

func highlight(active: bool) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	var target := original_color
	if active:
		target = Color(0.56, 0.0, 0.57, 1.0)
	else:
		target = original_color
	
	tween.tween_property(highlight_mat, "albedo_color", target, 0.25)
