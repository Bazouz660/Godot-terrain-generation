extends Node3D
class_name TerrainGenerator

@export var config: TerrainConfig
@export var origin: Node3D

var terrain_chunks: Dictionary[Vector2i, TerrainChunk] = {}
var timer := Timer.new()
var current_thread_usage: int = 0
var chunk_queue: Array[Vector2i] = []
var queued_chunks: Dictionary[Vector2i, bool] = {}

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
	if not queued_chunks.has(grid_position):
		chunk_queue.push_back(grid_position)
		queued_chunks[grid_position] = true

func _process_chunk_queue():
	if chunk_queue.size() > 0 and current_thread_usage < config.max_threads:
		var grid_position = chunk_queue.pop_front()
		queued_chunks.erase(grid_position)
		_create_chunk(grid_position.x, grid_position.y)

func _create_chunk(x: int, z: int):
	var chunk = TerrainChunk.new(Vector2i(x, z))
	chunk.position = Vector3(x * config.chunk_size, 0, z * config.chunk_size)
	add_child(chunk)
	terrain_chunks[chunk.grid_position] = chunk
	chunk.generate()
	current_thread_usage += 1
	chunk.generated.connect(on_chunk_generated)

func on_chunk_generated(_grid_position: Vector2i):
	current_thread_usage -= 1

func world_to_grid_position(world_position: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_position.x / config.chunk_size),
		floori(world_position.z / config.chunk_size)
	)

func _refresh_chunks():
	var player_grid_position = world_to_grid_position(origin.global_transform.origin)
	_unload_chunks(player_grid_position)
	_load_chunks(player_grid_position)
	_refresh_chunk_queue(player_grid_position)

func _unload_chunks(player_grid_position: Vector2i):
	var view_distance_sq = config.view_distance * config.view_distance
	for chunk in terrain_chunks.values().duplicate():
		var delta = chunk.grid_position - player_grid_position
		if delta.x * delta.x + delta.y * delta.y > view_distance_sq and not chunk.generating:
			_delete_chunk.call_deferred(chunk)

func _load_chunks(player_grid_position: Vector2i):
	var view_distance = config.view_distance
	var view_distance_sq = view_distance * view_distance
	for x in range(-view_distance, view_distance + 1):
		var x_sq = x * x
		if x_sq > view_distance_sq:
			continue
		for z in range(-view_distance, view_distance + 1):
			if x_sq + z * z > view_distance_sq:
				continue
			var check_position = Vector2i(x, z) + player_grid_position
			if not terrain_chunks.has(check_position):
				add_chunk_to_queue(check_position)

func _refresh_chunk_queue(player_grid_position: Vector2i):
	var view_distance_sq = config.view_distance * config.view_distance

	# Clean up out-of-range queued chunks
	for i in range(chunk_queue.size() - 1, -1, -1):
		var grid_position = chunk_queue[i]
		var delta = grid_position - player_grid_position
		if delta.x * delta.x + delta.y * delta.y > view_distance_sq:
			chunk_queue.remove_at(i)
			queued_chunks.erase(grid_position)

	# Sort queue by distance to player (closest first)
	chunk_queue.sort_custom(func(a, b):
		var delta_a = a - player_grid_position
		var delta_b = b - player_grid_position
		return delta_a.x * delta_a.x + delta_a.y * delta_a.y < delta_b.x * delta_b.x + delta_b.y * delta_b.y
	)


func _process(delta):
	_process_chunk_queue()

	var frame_time_ms = delta * 1000
	if frame_time_ms > 8.0:
		print("Frame time: ", frame_time_ms, "ms")

	var label = %Label as Label
	var world_pos := origin.global_transform.origin

	var continentalness = config.continentalness.noise.get_noise_2d(world_pos.x, world_pos.z)
	var peaks_and_valeys = config.peaks_and_valeys.noise.get_noise_2d(world_pos.x, world_pos.z)
	var erosion = config.erosion.noise.get_noise_2d(world_pos.x, world_pos.z)

	var humidity = config.humidity.noise.get_noise_2d(world_pos.x, world_pos.z)
	var temperature = config.temperature.noise.get_noise_2d(world_pos.x, world_pos.z)
	var difficulty = config.difficulty.noise.get_noise_2d(world_pos.x, world_pos.z)

	var height = TerrainChunk.sample_height(world_pos.x, world_pos.z)

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
