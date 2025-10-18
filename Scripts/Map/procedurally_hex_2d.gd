extends Node3D

@export var map_radius: int = 100
@export var hex_size: float = 1.0
@export var addon_size: float = 1.0
@export var hex_scene: PackedScene
@export var noise_scale: float = 25.0
@export var biome_noise_scale: float = 85.0  # Different scale for biome variety
@export var noise_seed: int = 123
@export var nr_regions: int = 4
@export var river_length: int = 100

var ready_hexes = 0
var hex_data: Dictionary = {}
var perlin_noise: FastNoiseLite
var biome_noise: FastNoiseLite  # Second noise layer for biome clustering
var biome_scenes: Dictionary = {}
var addon_scenes: Dictionary = {}

func _ready():
	load_biome_scenes()
	load_addon_scenes()
	randomize()
	noise_seed = randi_range(1, 1000)
	setup_noise()
	generate_hex_map()
	generate_rivers()
	generate_regions()
	assign_biomes()
	spawn_all_hexes()

func setup_noise():
	# Elevation noise
	perlin_noise = FastNoiseLite.new()
	perlin_noise.seed = noise_seed
	perlin_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	perlin_noise.frequency = 1.0 / noise_scale
	
	# Biome clustering noise (different seed, different scale)
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = noise_seed + 1000
	biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	biome_noise.frequency = 1.0 / biome_noise_scale

func load_addon_scenes():
	addon_scenes["dungeon_low"] = [
		load("res://Scenes/Map/Hexes/Plains/Hex_Plains_1.tscn")
	]
	addon_scenes["shop_gear"] = [
		load("res://Scenes/Map/Hexes/Plains/Hex_Plains_1.tscn")
	]
	addon_scenes["event_roll"] = [
		load("res://Scenes/Map/Hexes/Plains/Hex_Plains_1.tscn")
	]
	addon_scenes["event_combat"] = [
		load("res://Scenes/Map/Hexes/Plains/Hex_Plains_1.tscn")
	]
	addon_scenes["quest_low"] = [
		load("res://Scenes/Map/Hexes/Plains/Hex_Plains_1.tscn")
	]
	addon_scenes["shop_relic"] = [
		load("res://Scenes/Map/Hexes/Plains/Hex_Plains_1.tscn")
	]

func load_biome_scenes():
	biome_scenes["plains"] = [
		load("res://Scenes/Map/Hexes/Plains/Hex_Plains_1.tscn")
		]
	biome_scenes["forest"] = [
		load("res://Scenes/Map/Hexes/Forest/Hex_Forest_1.tscn")
		]
	biome_scenes["charred"] = [
		load("res://Scenes/Map/Hexes/Charred/Hex_Charred_1.tscn")
		]
	biome_scenes["mountain"] = [
		load("res://Scenes/Map/Hexes/mountain/Hex_Mountain_1.tscn")
		]
	biome_scenes["tundra"] = [
		load("res://Scenes/Map/Hexes/Tundra/Hex_Tundra_1.tscn")
		]
	biome_scenes["desert"] = [
		load("res://Scenes/Map/Hexes/Desert/Hex_Desert_1.tscn")
		]
	biome_scenes["snowy"] = [
		load("res://Scenes/Map/Hexes/Snowy/Hex_Snowy_1.tscn")
		]
	biome_scenes["void"] = [
		load("res://Scenes/Map/Hexes/Void/Hex_Void_1.tscn")
		]
	biome_scenes["river"] = [
		load("res://Scenes/Map/Hexes/Hex_water_1.tscn")
		]
	biome_scenes["water"] = [
		load("res://Scenes/Map/Hexes/Hex_water_1.tscn")
		]

func generate_hex_map():
	for q in range(-map_radius, map_radius + 1):
		for r in range(-map_radius, map_radius + 1):
			var s = -q - r
			if abs(s) <= map_radius:
				var world_pos = hex_to_world(q, r)
				var elevation_value = (perlin_noise.get_noise_2d(world_pos.x, world_pos.y) + 1.0) / 2.0
				var hex = Hexdata.new()
				hex.q = q
				hex.r = r
				hex.elevation = elevation_value
				hex_data[Vector2i(q, r)] = hex

func get_hex_neighbors(hex_key: Vector2i) -> Array:
	var q = hex_key.x
	var r = hex_key.y
	return [
		Vector2i(q+1, r), Vector2i(q-1, r),
		Vector2i(q, r+1), Vector2i(q, r-1),
		Vector2i(q+1, r-1), Vector2i(q-1, r+1),
	]

func assign_biomes():
	for key in hex_data:
		var hex = hex_data[key]
		
		if hex.has_river:
			hex.biome = "river"
			continue
		
		# Very low elevation = always water
		if hex.elevation < 0.18:
			hex.biome = "water"
		
		# Very high elevation = always charred/void
		elif hex.elevation > 0.78:
			hex.biome = "charred"
		
		# Everything else: use biome noise to cluster different biomes
		else:
			var world_pos = hex_to_world(hex.q, hex.r)
			var biome_val = (biome_noise.get_noise_2d(world_pos.x, world_pos.y) + 1.0) / 2.0
			
			# Assign biome based on BOTH elevation and biome_noise
			hex.biome = get_biome_from_noise(hex.elevation, biome_val)

func get_biome_from_noise(elevation: float, biome_noise_val: float) -> String:
	# High elevation band (0.65-0.78)
	if elevation > 0.65:
		if biome_noise_val > 0.6:
			return "mountain"
		elif biome_noise_val > 0.3:
			return "snowy"
		else:
			return "tundra"
	
	# Mid-high band (0.50-0.65)
	elif elevation > 0.50:
		if biome_noise_val > 0.65:
			return "mountain"
		elif biome_noise_val > 0.4:
			return "forest"
		elif biome_noise_val > 0.2:
			return "tundra"
		else:
			return "plains"
	
	# Mid band (0.35-0.50)
	elif elevation > 0.35:
		if biome_noise_val > 0.7:
			return "mountain"
		elif biome_noise_val > 0.5:
			return "plains"
		elif biome_noise_val > 0.3:
			return "desert"
		else:
			return "forest"
	
	# Low-mid band (0.25-0.35)
	elif elevation > 0.25:
		if biome_noise_val > 0.6:
			return "forest"
		elif biome_noise_val > 0.4:
			return "tundra"
		elif biome_noise_val > 0.2:
			return "plains"
		else:
			return "desert"
	
	# Low band (0.18-0.25)
	else:
		if biome_noise_val > 0.5:
			return "desert"
		else:
			return "plains"

func spawn_all_hexes():
	for key in hex_data:
		var hex = hex_data[key]
		spawn_hex(hex)

func spawn_hex(hex: Hexdata):
	var scenes_for_biome = biome_scenes[hex.biome]
	var random_scene = scenes_for_biome[randi() % scenes_for_biome.size()]
	var hex_instance = random_scene.instantiate()
	hex_instance.setup(hex)
	var world_pos = hex_to_world(hex.q, hex.r)
	
	hex_instance.position = Vector3(world_pos.x, 0, world_pos.y)
	hex_instance.scale = Vector3.ONE * hex_size
	hex_instance.hex_data = hex

	if hex_instance.can_spawn_addon():
		trace_addon(hex)

	add_child(hex_instance)

func generate_regions():
	var region_seeds = []
	var keys = hex_data.keys()
	for i in range(nr_regions):
		var found: bool = false
		while not found:
			var random_key = keys[randi() % keys.size()]
			var hex = hex_data[random_key]
			if hex.elevation > 0.18:
				region_seeds.append(random_key)
				hex.region_id = i
				found = true

	var queue: Array = []
	for seed in region_seeds:
		queue.append(seed)

	while not queue.is_empty():
		var current_key = queue.pop_front()
		var current_hex = hex_data[current_key]
		var neighbors = get_hex_neighbors(current_key)

		for neighbor_key in neighbors:
			if neighbor_key not in hex_data:
				continue

			var neighbor = hex_data[neighbor_key]
			if neighbor.region_id == -1 and neighbor.elevation > 0.18:
				neighbor.region_id = current_hex.region_id
				queue.append(neighbor_key)

func generate_addon():
	for key in hex_data:
		var hex = hex_data[key]
		if hex.is_flat:
			trace_addon(hex)

func trace_addon(hex: Hexdata):
	var current = hex
	var has = randi_range(0, 30)
	var addon_type = randi_range(1, 6)

	if has == 0:
		return
	elif has == 30:
		if addon_type == 1:
			current.addon_type = "dungeon_low"
		if addon_type == 2:
			current.addon_type = "shop_gear"
		if addon_type == 3:
			current.addon_type = "event_roll"
		if addon_type == 4:
			current.addon_type = "event_combat"
		if addon_type == 5:
			current.addon_type = "quest_low"
		if addon_type == 6:
			current.addon_type = "shop_relic"

		var scenes_for_addon = addon_scenes[current.addon_type]
		var random_scene = scenes_for_addon[randi() % scenes_for_addon.size()]
		var addon_instance = random_scene.instantiate()
		var world_pos = hex_to_world(current.q, current.r)
		addon_instance.position = Vector3(world_pos.x, 0.2, world_pos.y)
		addon_instance.scale = Vector3.ONE * addon_size

		add_child(addon_instance)

func generate_rivers():
	for key in hex_data:
		var hex = hex_data[key]
		if hex.elevation > 0.64:
			trace_river(hex)

func trace_river(hex: Hexdata):
	var current = hex
	var steps = 0
	var max_length = river_length

	while steps < max_length:
		current.has_river = true
		var neighbors = get_hex_neighbors(Vector2i(current.q, current.r))
		var lowest_neighbor = null
		var lowest_elevation = current.elevation

		for neighbor_key in neighbors:
			if neighbor_key not in hex_data:
				continue
			var neighbor = hex_data[neighbor_key]
			if neighbor.biome == "water":
				return
			if neighbor.elevation < lowest_elevation:
				lowest_neighbor = neighbor
				lowest_elevation = neighbor.elevation
		if lowest_neighbor:
			current = lowest_neighbor
		else:
			break
		steps += 1

func hex_to_world(q: int, r: int) -> Vector2:
	var x = hex_size * sqrt(3) * (q + r / 2.0)
	var y = hex_size * 3.0 / 2.0 * r
	return Vector2(x, y)
