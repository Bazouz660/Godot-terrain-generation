extends Resource
class_name TerrainConfig

signal debug_toggled(state: bool)

@export var chunk_size: int = 16
@export var vertex_per_meter: int = 4
@export var view_distance: int = 3
@export var update_rate: float = 1.0
@export var world_seed: int = 0
@export var max_threads: int = 4

@export var height_scale: float = 1.0

@export var continentalness: NoiseTexture2D
@export var continentalness_curve: Curve

@export var peaks_and_valeys: NoiseTexture2D
@export var peaks_and_valeys_curve: Curve

@export var erosion: NoiseTexture2D
@export var erosion_curve: Curve

@export var humidity: NoiseTexture2D
@export var temperature: NoiseTexture2D
@export var difficulty: NoiseTexture2D

@export var material: Material
@export var chunk_borders_material: Material

@export var show_chunk_borders: bool = false:
	set(value):
		if value != show_chunk_borders:
			show_chunk_borders = value
			debug_toggled.emit(value)

@export var water_material: Material
@export var sea_level: float = 0.0

@export var biomes: Array[Biome] = []

func setup():
	(continentalness.noise as FastNoiseLite).seed = world_seed
	(peaks_and_valeys.noise as FastNoiseLite).seed = world_seed + 1
	(erosion.noise as FastNoiseLite).seed = world_seed + 2
	(humidity.noise as FastNoiseLite).seed = world_seed + 3
	(temperature.noise as FastNoiseLite).seed = world_seed + 4
	(difficulty.noise as FastNoiseLite).seed = world_seed + 5
