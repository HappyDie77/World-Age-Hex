extends Node3D

@export var map_radius: int = 50           # How far the hex map extends from center
@export var hex_size: float = 1.0         # Size scale of hex tiles
@export var hex_scene: PackedScene        # Assign your HexTile.tscn here in the inspector

func _ready():
	generate_hex_map()

# --- Generate all the hex tiles ---
func generate_hex_map():
	for q in range(-map_radius, map_radius + 1):
		for r in range(-map_radius, map_radius + 1):
			var s = -q - r
			# The condition makes a nice hex-shaped map instead of a square grid
			if abs(s) <= map_radius:
				spawn_hex(q, r)

# --- Spawn a single hex at position ---
func spawn_hex(q: int, r: int):
	var hex_instance = hex_scene.instantiate()
	# Convert hex coordinate to world position
	var pos = hex_to_world(q, r)
	# In 3D, Y is height, so we use (x, 0, z)
	hex_instance.position = Vector3(pos.x, 0, pos.y)
	# Optional: scale or color variation
	hex_instance.scale = Vector3.ONE * hex_size
	# Add to the scene
	add_child(hex_instance)

# --- Convert (q, r) hex coordinates into 2D world space ---
func hex_to_world(q: int, r: int) -> Vector2:
	var x = hex_size * sqrt(3) * (q + r / 2.0)
	var y = hex_size * 3.0 / 2.0 * r
	return Vector2(x, y)
