extends Node3D
class_name TerrainChunk

# import variables
static var config: TerrainConfig
var size: int
var vertex_count: int # New variable to store number of vertices per side

# private variables
var mesh_instance: MeshInstance3D
var water_mesh_instance: MeshInstance3D
var grid_position: Vector2i
var height_data: Array[float] = []
var biome_data: Array[int] = []
static var biomes_label_index: Dictionary[String, Biome] = {}
static var biomes_index_label: Dictionary[int, Biome] = {}

# public variables
var generating: bool = false

var rng := RandomNumberGenerator.new()

signal _generated(meshes: Dictionary)
signal generated(position: Vector2i)

static var biomes: Array[Biome]

static var max_height: float = -INF
static var min_height: float = INF

static func set_config(p_config: TerrainConfig) -> void:
	config = p_config
	biomes = config.biomes
	_setup_shader_parameters()

static func _setup_shader_parameters():
	var shader_material = config.material

	# Convert biome data to arrays for the shader
	var colors: Array[Color] = []
	var height_ranges: Array[Vector2] = []
	var humidity_ranges: Array[Vector2] = []
	var temperature_ranges: Array[Vector2] = []
	var difficulty_ranges: Array[Vector2] = []
	var strict_height: Array[bool] = []

	for biome in biomes:
		colors.append(biome.color)
		height_ranges.append(biome.height_range)
		humidity_ranges.append(biome.humidity_range)
		temperature_ranges.append(biome.temperature_range)
		difficulty_ranges.append(biome.difficulty_range)
		strict_height.append(biome.strict_height)

		# add to index
		biomes_label_index[biome.label] = biome
		biomes_index_label[biome.id] = biome

		if biome.height_range.y > max_height:
			max_height = biome.height_range.y
		if biome.height_range.x < min_height:
			min_height = biome.height_range.x

	shader_material.set_shader_parameter("biome_colors", colors)
	shader_material.set_shader_parameter("height_ranges", height_ranges)
	shader_material.set_shader_parameter("humidity_ranges", humidity_ranges)
	shader_material.set_shader_parameter("temperature_ranges", temperature_ranges)
	shader_material.set_shader_parameter("difficulty_ranges", difficulty_ranges)
	shader_material.set_shader_parameter("biome_count", biomes.size())
	shader_material.set_shader_parameter("max_height", max_height)
	shader_material.set_shader_parameter("min_height", min_height)
	shader_material.set_shader_parameter("strict_height", strict_height)


func _funny_randf(from: float, to: float):
	return rng.randf_range(from, to)

func _generate_features_positions() -> Dictionary[Vector2i, Array]:
	var positions: Dictionary[Vector2i, Array] = {}
	var occupied_positions: Array[Vector2i] = []

	var biome_index := 0
	for biome in biomes:
		var feature_index := 0
		for feature_params in biome.features:
			feature_params = feature_params as FeatureGenParams
			var density = feature_params.density
			var positions_list = []
			for z in range(vertex_count):
				for x in range(vertex_count):

					if occupied_positions.find(Vector2i(x, z)) != -1:
						continue

					if biome_data[z * vertex_count + x] != biome_index:
						continue

					var world_x = (float(x) / config.vertex_per_meter) + (grid_position.x * size)
					var world_z = (float(z) / config.vertex_per_meter) + (grid_position.y * size)
					if density > _funny_randf(0.0, 100.0):
						var feature = feature_params.feature as Feature
						var random_offset_x = _funny_randf(-feature.random_offset.x, feature.random_offset.x)
						var random_offset_z = _funny_randf(-feature.random_offset.z, feature.random_offset.z)
						var random_offset_y = _funny_randf(-feature.random_offset.y, feature.random_offset.y)
						world_x += random_offset_x
						world_z += random_offset_z
						var height = get_interpolated_height_at_world_position(Vector3(world_x, 0.0, world_z))
						height += random_offset_y
						var pos = Vector3(world_x, height, world_z)
						positions_list.append(pos)
						occupied_positions.append(Vector2i(x, z))

			if positions_list.size() > 0:
				positions[Vector2i(biome_index, feature_index)] = positions_list
			feature_index += 1
		biome_index += 1

	return positions

func _init(p_grid_position: Vector2i):
	size = config.chunk_size
	vertex_count = int(size * config.vertex_per_meter) + 1 # Calculate vertices based on density
	grid_position = p_grid_position

func _ready():
	_generated.connect(_on_chunk_generated)
	mesh_instance = MeshInstance3D.new()
	water_mesh_instance = MeshInstance3D.new()
	water_mesh_instance.position.x += size * 0.5
	water_mesh_instance.position.z += size * 0.5
	add_child(water_mesh_instance)
	add_child(mesh_instance)

func generate():
	generating = true
	WorkerThreadPool.add_task(_generate)

func get_height_at_world_position(world_position: Vector3) -> float:
	var local_position = world_position - global_transform.origin
	var x = int(local_position.x * config.vertex_per_meter)
	var z = int(local_position.z * config.vertex_per_meter)
	if x < 0 or x >= vertex_count or z < 0 or z >= vertex_count:
		return 0.0
	return height_data[z * vertex_count + x]

func get_interpolated_height_at_world_position(world_position: Vector3) -> float:
	# Get the floor of the coordinates
	var x_floor: float = floor(world_position.x)
	var z_floor: float = floor(world_position.z)

	# Sample heights at the four corners
	var h00 := _sample_height(x_floor, z_floor)
	var h01 := _sample_height(x_floor + 1.0, z_floor)
	var h10 := _sample_height(x_floor, z_floor + 1.0)
	var h11 := _sample_height(x_floor + 1.0, z_floor + 1.0)

	# Calculate interpolation ratios
	var x_ratio := world_position.x - x_floor
	var z_ratio := world_position.z - z_floor

	# Perform bilinear interpolation
	var h0: float = lerp(h00, h01, x_ratio)
	var h1: float = lerp(h10, h11, x_ratio)

	return lerp(h0, h1, z_ratio)


static func _sample_height(world_x: float, world_z: float) -> float:
	var continentalness = config.continentalness.noise.get_noise_2d(world_x, world_z)
	var peaks_and_valeys = config.peaks_and_valeys.noise.get_noise_2d(world_x, world_z)
	var erosion = config.erosion.noise.get_noise_2d(world_x, world_z)

	# var continentalness_normalized = (continentalness + 1.0) / 2.0
	# erosion *= continentalness_normalized

	var continentalness_height = config.continentalness_curve.sample(continentalness)
	var peaks_and_valeys_height = config.peaks_and_valeys_curve.sample(peaks_and_valeys)
	var erosion_height = config.erosion_curve.sample(erosion)
	var height = continentalness_height + erosion_height + peaks_and_valeys_height
	return height

static func determine_biome(world_x: float, world_z: float) -> Biome:
	var height = _sample_height(world_x, world_z)
	var humidity = config.humidity.noise.get_noise_2d(world_x, world_z)
	var temperature = config.temperature.noise.get_noise_2d(world_x, world_z)
	var difficulty = config.difficulty.noise.get_noise_2d(world_x, world_z)

	var best_biome: Biome = null
	var best_score: float = -1.0

	for b in biomes:
		var score = 0.0

		# Calculate score for height
		var height_diff = abs(height - (b.height_range.x + b.height_range.y) / 2.0)
		var height_range = (b.height_range.y - b.height_range.x) / 2.0
		var height_score = 1.0 - (height_diff / height_range)
		if height_score < 0:
			height_score *= 20.0 # Penalize more for being out of range
		score += height_score

		# Calculate score for humidity
		var humidity_diff = abs(humidity - (b.humidity_range.x + b.humidity_range.y) / 2.0)
		var humidity_range = (b.humidity_range.y - b.humidity_range.x) / 2.0
		var humidity_score = 1.0 - (humidity_diff / humidity_range)
		if humidity_score < 0:
			humidity_score *= 2.0 # Penalize more for being out of range
		score += humidity_score

		# Calculate score for temperature
		var temperature_diff = abs(temperature - (b.temperature_range.x + b.temperature_range.y) / 2.0)
		var temperature_range = (b.temperature_range.y - b.temperature_range.x) / 2.0
		var temperature_score = 1.0 - (temperature_diff / temperature_range)
		if temperature_score < 0:
			temperature_score *= 2.0 # Penalize more for being out of range
		score += temperature_score

		# Calculate score for difficulty
		var difficulty_diff = abs(difficulty - (b.difficulty_range.x + b.difficulty_range.y) / 2.0)
		var difficulty_range = (b.difficulty_range.y - b.difficulty_range.x) / 2.0
		var difficulty_score = 1.0 - (difficulty_diff / difficulty_range)
		if difficulty_score < 0:
			difficulty_score *= 2.0 # Penalize more for being out of range
		score += difficulty_score

		# Update best biome if current biome has a higher score
		if score > best_score:
			best_score = score
			best_biome = b

	return best_biome


static func _compute_normal(world_x: float, world_z: float) -> Vector3:
	var vertex_spacing = 1.0 / config.vertex_per_meter
	# Get the heights of the neighboring vertices
	var left = _sample_height(world_x, world_z)
	var right = _sample_height(world_x + 1, world_z)
	var bottom = _sample_height(world_x, world_z + 1)
	var top = _sample_height(world_x + 1, world_z + 1)

	# Calculate the differences in height, accounting for vertex spacing
	var dx = (right - left) / vertex_spacing
	var dz = (bottom - top) / vertex_spacing

	# Compute the normal vector
	var normal = Vector3(-dx, 2.0, -dz).normalized()
	return normal

func _generate_water_mesh() -> PlaneMesh:
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(size, size)
	mesh.subdivide_depth = vertex_count - 1
	mesh.subdivide_width = vertex_count - 1
	return mesh

func _generate() -> void:
	rng.seed = hash(config.world_seed + grid_position.x * grid_position.y)

	height_data.resize(vertex_count * vertex_count)
	biome_data.resize(vertex_count * vertex_count)

	var mesh = _generate_mesh()
	var water_mesh = _generate_water_mesh()
	var feature_positions: Dictionary[Vector2i, Array] = _generate_features_positions()

	var data = {
		"mesh": mesh,
		"water_mesh": water_mesh,
		"feature_positions": feature_positions
	}

	_generated.emit.call_deferred(data)
	generated.emit.call_deferred(grid_position)

# normalizes noise values from -1 to 1 to 0 to 1
static func normalize_noise_value(value: float) -> float:
	return (value + 1.0) / 2.0

func _generate_mesh() -> ArrayMesh:
	var vertex_spacing = 1.0 / config.vertex_per_meter

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	st.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT) # For continentalness, erosion, peaks_valleys
	st.set_custom_format(1, SurfaceTool.CUSTOM_RGB_FLOAT) # For humidity, temperature, difficulty

	# Generate grid vertices with noise-based height
	for z in range(vertex_count):
		for x in range(vertex_count):
			var world_x = (float(x) / config.vertex_per_meter) + (grid_position.x * size)
			var world_z = (float(z) / config.vertex_per_meter) + (grid_position.y * size)

			# Sample all noise values
			var continentalness = config.continentalness.noise.get_noise_2d(world_x, world_z)
			var erosion = config.erosion.noise.get_noise_2d(world_x, world_z)
			var peaks_valleys = config.peaks_and_valeys.noise.get_noise_2d(world_x, world_z)
			var humidity = config.humidity.noise.get_noise_2d(world_x, world_z)
			var temperature = config.temperature.noise.get_noise_2d(world_x, world_z)
			var difficulty = config.difficulty.noise.get_noise_2d(world_x, world_z)


			var height = _sample_height(world_x, world_z)
			height_data[z * vertex_count + x] = height
			var vertex = Vector3(x * vertex_spacing, height, z * vertex_spacing)
			var uv = Vector2(float(x) / (vertex_count - 1), float(z) / (vertex_count - 1))
			st.set_uv(uv)
			var color := Color.PURPLE
			var biome = determine_biome(world_x, world_z)
			biome_data[z * vertex_count + x] = biome.id
			if biome:
				color = biome.color

			# Store in custom attributes (RGB format)
			st.set_custom(0, color)

			# Normalize the height value to [0, 1] range using min and max height
			var normalized_height = (height - min_height) / (max_height - min_height)

			st.set_custom(0, Color(normalized_height, humidity, temperature))
			st.set_custom(1, Color(difficulty, 0.0, 0.0))
			st.set_color(color)
			st.set_normal(_compute_normal(world_x, world_z))
			st.add_vertex(vertex)

	# Generate indices for triangles
	for z in range(vertex_count - 1):
		for x in range(vertex_count - 1):
			var i = z * vertex_count + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + vertex_count)

			st.add_index(i + 1)
			st.add_index(i + vertex_count + 1)
			st.add_index(i + vertex_count)

	return st.commit()

func _instantiate_features(feature_positions: Dictionary[Vector2i, Array]) -> void:
	for i in range(feature_positions.size()):
		var key = feature_positions.keys()[i]
		var positions = feature_positions[key]
		var biome = biomes_index_label[key.x]
		var feature := biome.features[key.y].feature as Feature

		if not feature:
			continue

		if feature.type == Feature.FeatureType.INSTANCE:
			_instantiate_instances(feature, positions)
		elif feature.type == Feature.FeatureType.MULTIMESH:
			_instantiate_multimesh(biome, feature, positions)


func _instantiate_multimesh(biome: Biome, feature: Feature, positions: Array) -> void:
	var multimesh_instance := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = positions.size()
	multimesh.mesh = feature.mesh
	for i in range(positions.size()):
		multimesh.set_instance_transform(i, Transform3D(Basis(), positions[i]))
	multimesh_instance.multimesh = multimesh
	multimesh_instance.cast_shadow = feature.cast_shadow

	if feature.receive_biome_color:
		var material := multimesh.mesh.surface_get_material(0)
		if material is ShaderMaterial:
			var material_duplicated = material.duplicate() as ShaderMaterial
			material_duplicated.set_shader_parameter(feature.shader_parameter_color_name, biome.color)
			multimesh_instance.material_override = material_duplicated


	add_child(multimesh_instance)
	multimesh_instance.global_transform.origin = Vector3(0.0, 0.0, 0.0)

func _instantiate_instances(feature: Feature, positions: Array) -> void:
	for pos in positions:
		var instance := feature.scene.instantiate() as Node3D
		add_child(instance)
		instance.global_position = pos
		instance.global_rotation = Vector3(0.0, deg_to_rad(_funny_randf(feature.random_rotation.x, feature.random_rotation.y)), 0.0)
		var random_scale = _funny_randf(feature.random_scale.x, feature.random_scale.y)
		instance.scale = Vector3(random_scale, random_scale, random_scale)


func _on_chunk_generated(data: Dictionary) -> void:

	generating = false
	mesh_instance.mesh = data["mesh"]
	water_mesh_instance.mesh = data["water_mesh"]
	mesh_instance.material_override = config.material
	water_mesh_instance.material_override = config.water_material
	water_mesh_instance.position.y = config.sea_level

	_instantiate_features(data["feature_positions"])
