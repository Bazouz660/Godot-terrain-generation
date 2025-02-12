extends Node
class_name TerrainChunkBiome

static func _get_best_biome(height: float, humidity: float, temperature: float, difficulty: float) -> Biome:
	var best_biome: Biome = null
	var best_score: float = -1.0

	for b in TerrainChunk.biomes:
		var score = 0.0

		# Height scoring
		var height_diff = abs(height - ((b.height_range.x + b.height_range.y) / 2.0))
		var height_range = (b.height_range.y - b.height_range.x) / 2.0
		var height_score = 1.0 - (height_diff / height_range)
		if height_score < 0:
			height_score *= 20.0
		score += height_score

		# Humidity scoring
		var humidity_diff = abs(humidity - ((b.humidity_range.x + b.humidity_range.y) / 2.0))
		var humidity_range = (b.humidity_range.y - b.humidity_range.x) / 2.0
		var humidity_score = 1.0 - (humidity_diff / humidity_range)
		if humidity_score < 0:
			humidity_score *= 2.0
		score += humidity_score

		# Temperature scoring
		var temperature_diff = abs(temperature - ((b.temperature_range.x + b.temperature_range.y) / 2.0))
		var temperature_range = (b.temperature_range.y - b.temperature_range.x) / 2.0
		var temperature_score = 1.0 - (temperature_diff / temperature_range)
		if temperature_score < 0:
			temperature_score *= 2.0
		score += temperature_score

		# Difficulty scoring
		var difficulty_diff = abs(difficulty - ((b.difficulty_range.x + b.difficulty_range.y) / 2.0))
		var difficulty_range = (b.difficulty_range.y - b.difficulty_range.x) / 2.0
		var difficulty_score = 1.0 - (difficulty_diff / difficulty_range)
		if difficulty_score < 0:
			difficulty_score *= 2.0
		score += difficulty_score

		if score > best_score:
			best_score = score
			best_biome = b

	return best_biome

static func _determine_biome(chunk: TerrainChunk, world_x: float, world_z: float) -> Biome:
	var height = TerrainChunkNoise._sample_height(chunk, world_x, world_z)
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
