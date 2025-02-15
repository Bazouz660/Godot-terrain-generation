extends Node
class_name TerrainChunkBiome

static func _get_best_biome(height: float, humidity: float, temperature: float, difficulty: float) -> Biome:
	var best_biome: Biome = null
	var best_score: float = -1.0
	# A small constant to avoid division by zero.
	var EPSILON = 0.0001

	for b in TerrainChunk.biomes:
		var score = 0.0

		# --- Height Scoring ---
		var height_center = (b.height_range.x + b.height_range.y) / 2.0
		var height_range = (b.height_range.y - b.height_range.x) / 2.0
		var safe_height_range = max(height_range, EPSILON)
		var height_diff = abs(height - height_center)
		var height_base_score = 1.0 - (height_diff / safe_height_range)
		if height_diff <= safe_height_range:
			# In-range: boost score by inverse of the range.
			score += height_base_score * (1.0 / safe_height_range)
		else:
			# Out-of-range: apply a constant penalty (here 20.0 as before).
			score += height_base_score * 200000.0

		# --- Humidity Scoring ---
		var humidity_center = (b.humidity_range.x + b.humidity_range.y) / 2.0
		var humidity_range = (b.humidity_range.y - b.humidity_range.x) / 2.0
		var safe_humidity_range = max(humidity_range, EPSILON)
		var humidity_diff = abs(humidity - humidity_center)
		var humidity_base_score = 1.0 - (humidity_diff / safe_humidity_range)
		if humidity_diff <= safe_humidity_range:
			score += humidity_base_score * (1.0 / safe_humidity_range)
		else:
			score += humidity_base_score * 2.0

		# --- Temperature Scoring ---
		var temperature_center = (b.temperature_range.x + b.temperature_range.y) / 2.0
		var temperature_range = (b.temperature_range.y - b.temperature_range.x) / 2.0
		var safe_temperature_range = max(temperature_range, EPSILON)
		var temperature_diff = abs(temperature - temperature_center)
		var temperature_base_score = 1.0 - (temperature_diff / safe_temperature_range)
		if temperature_diff <= safe_temperature_range:
			score += temperature_base_score * (1.0 / safe_temperature_range)
		else:
			score += temperature_base_score * 2.0

		# --- Difficulty Scoring ---
		var difficulty_center = (b.difficulty_range.x + b.difficulty_range.y) / 2.0
		var difficulty_range = (b.difficulty_range.y - b.difficulty_range.x) / 2.0
		var safe_difficulty_range = max(difficulty_range, EPSILON)
		var difficulty_diff = abs(difficulty - difficulty_center)
		var difficulty_base_score = 1.0 - (difficulty_diff / safe_difficulty_range)
		if difficulty_diff <= safe_difficulty_range:
			score += difficulty_base_score * (1.0 / safe_difficulty_range)
		else:
			score += difficulty_base_score * 2.0

		if score > best_score:
			best_score = score
			best_biome = b

	return best_biome

static func _determine_biome(chunk: TerrainChunk, world_x: float, world_z: float) -> Biome:
	var height = chunk.get_height_at_world_position(Vector3(world_x, 0.0, world_z))
	var index = chunk.get_index_from_world_coords(world_x, world_z)
	var humidity = chunk.humidity_data[index]
	var temperature = chunk.temperature_data[index]
	var difficulty = chunk.difficulty_data[index]
	return _get_best_biome(height, humidity, temperature, difficulty)

static func determine_biome(world_x: float, world_z: float) -> Biome:
	var config = TerrainChunk.config
	var continentalness = config.continentalness.noise.get_noise_2d(world_x, world_z)
	var erosion = config.erosion.noise.get_noise_2d(world_x, world_z)
	var peaks_and_valleys = config.peaks_and_valeys.noise.get_noise_2d(world_x, world_z)
	var height = config.continentalness_curve.sample_baked(continentalness) + \
				 config.erosion_curve.sample_baked(erosion) + \
				 config.peaks_and_valeys_curve.sample_baked(peaks_and_valleys)

	var humidity = config.humidity.noise.get_noise_2d(world_x, world_z)
	var temperature = config.temperature.noise.get_noise_2d(world_x, world_z)
	var difficulty = config.difficulty.noise.get_noise_2d(world_x, world_z)
	return _get_best_biome(height, humidity, temperature, difficulty)
