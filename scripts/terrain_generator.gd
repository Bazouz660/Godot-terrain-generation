extends Node3D
class_name TerrainGenerator

@export var config: TerrainConfig
# the origin of the terrain
@export var origin: Node3D

var terrain_chunks: Dictionary[Vector2i, TerrainChunk] = {}
var timer := Timer.new()
var current_thread_usage: int = 0
var chunk_queue: Array[Vector2i] = []

func _ready():
	config.setup()
	TerrainChunk.set_config(config)
	timer.timeout.connect(_refresh_chunks)
	timer.wait_time = config.update_rate
	timer.one_shot = false
	timer.start.call_deferred()
	add_child(timer)

func _delete_chunk(chunk: TerrainChunk):
	terrain_chunks.erase(chunk.grid_position)
	chunk.queue_free()

func add_chunk_to_queue(grid_position: Vector2i):
	if not chunk_queue.has(grid_position):
		chunk_queue.push_back(grid_position)

func _process_chunk_queue():
	if chunk_queue.size() > 0 and current_thread_usage < config.max_threads:
		var grid_position = chunk_queue.pop_front()
		_create_chunk(grid_position.x, grid_position.y)

func _create_chunk(x: int, z: int):
	var chunk = TerrainChunk.new(Vector2i(x, z))
	chunk.position = Vector3(x * config.chunk_size, 0, z * config.chunk_size)
	add_child(chunk)
	terrain_chunks.get_or_add(chunk.grid_position, chunk)
	chunk.generate()
	current_thread_usage += 1
	chunk.generated.connect(on_chunk_generated)

func on_chunk_generated(_grid_position: Vector2i):
	current_thread_usage -= 1

func world_to_grid_position(world_position: Vector3) -> Vector2i:
	var x = floori(world_position.x / config.chunk_size)
	var z = floori(world_position.z / config.chunk_size)
	return Vector2i(x, z)

func is_in_view_distance(grid_position: Vector2i) -> bool:
	var origin_position = origin.global_transform.origin
	var origin_chunk_position = world_to_grid_position(origin_position)
	var distance = origin_chunk_position.distance_to(grid_position)
	return distance <= config.view_distance

func _unload_chunks():
	for chunk in terrain_chunks.values():
		if not is_in_view_distance(chunk.grid_position) and not chunk.generating:
			_delete_chunk(chunk)

func _load_chunks():
	var player_grid_position := world_to_grid_position(origin.global_transform.origin)
	var view_distance = config.view_distance

	for z in range(-view_distance, view_distance):
		for x in range(-view_distance, view_distance):
			var check_position := Vector2i(x, z) + player_grid_position
			if is_in_view_distance(check_position) and not terrain_chunks.has(check_position):
				add_chunk_to_queue(check_position)

func _refresh_chunk_queue():
	# check the queue for any chunks that are out of view distance
	for i in range(chunk_queue.size() - 1, -1, -1):
		var grid_position = chunk_queue[i]
		if not is_in_view_distance(grid_position):
			chunk_queue.remove_at(i)

func _get_current_chunk() -> TerrainChunk:
	var player_grid_position := world_to_grid_position(origin.global_transform.origin)
	return terrain_chunks.get(player_grid_position)

func _refresh_chunks():
	_unload_chunks()
	_load_chunks()
	_refresh_chunk_queue()

func _process(delta):
	_process_chunk_queue()

	var label = %Label as Label
	var world_pos := origin.global_transform.origin

	var continentalness = config.continentalness.noise.get_noise_2d(world_pos.x, world_pos.z)
	var peaks_and_valeys = config.peaks_and_valeys.noise.get_noise_2d(world_pos.x, world_pos.z)
	var erosion = config.erosion.noise.get_noise_2d(world_pos.x, world_pos.z)

	var humidity = config.humidity.noise.get_noise_2d(world_pos.x, world_pos.z)
	var temperature = config.temperature.noise.get_noise_2d(world_pos.x, world_pos.z)
	var difficulty = config.difficulty.noise.get_noise_2d(world_pos.x, world_pos.z)

	var height = TerrainChunk._sample_height(world_pos.x, world_pos.z)

	var biome = TerrainChunk.determine_biome(world_pos.x, world_pos.z)

	var continentalness_str = "%.2f" % continentalness
	var peaks_and_valeys_str = "%.2f" % peaks_and_valeys
	var erosion_str = "%.2f" % erosion
	var humidity_str = "%.2f" % humidity
	var temperature_str = "%.2f" % temperature
	var difficulty_str = "%.2f" % difficulty
	var height_str = "%.2f" % height
	var y_str = "%.2f" % world_pos.y
	var biome_str = biome.label if biome != null else "None"

	label.text = "Continentalness: " + continentalness_str + "\n" \
		+ "Peaks and Valeys: " + peaks_and_valeys_str + "\n" \
		+ "Erosion: " + erosion_str + "\n" \
		+ "Humidity: " + humidity_str + "\n" \
		+ "Temperature: " + temperature_str + "\n" \
		+ "Difficulty: " + difficulty_str + "\n" \
		+ "Height: " + height_str + "\n" \
		+ "Y: " + y_str + "\n" \
		+ "Biome: " + biome_str
