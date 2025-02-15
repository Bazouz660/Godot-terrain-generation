extends Node
class_name TerrainChunkStructures

# Apply structure deformations to a given chunk by querying the global structure manager.
static func _apply_deformations(chunk: TerrainChunk) -> void:
	# Create an AABB for the chunk (extend vertically to cover all terrain)
	var chunk_area = AABB(
		Vector3(chunk.world_offset_x, -1000, chunk.world_offset_z),
		Vector3(TerrainChunk.config.chunk_size, 2000, TerrainChunk.config.chunk_size)
	)

	# Get all global structures overlapping this chunk
	var structures = StructureManager.get_structures_in_area(chunk_area)

	# Process each structure
	for structure_data in structures:
		_apply_structure_deformation(chunk, structure_data)

# In TerrainChunkStructures.gd

static func _apply_structure_deformation(chunk: TerrainChunk, structure_data: StructureData) -> void:
	var config = TerrainChunk.config
	var structure_pos = structure_data.position
	var structure_size = structure_data.size

	# Calculate the footprint bounds in world coordinates
	var min_x = structure_pos.x
	var max_x = structure_pos.x + structure_size.x
	var min_z = structure_pos.z
	var max_z = structure_pos.z + structure_size.z

	# round min_x, max_x, min_z, max_z to the largest nearest integer for positive values and smallest for negative values
	min_x = floor(min_x)
	max_x = ceil(max_x)
	min_z = floor(min_z)
	max_z = ceil(max_z)

	# Apply the deformation to the terrain
	for x in range(int(min_x), int(max_x)):
		for z in range(int(min_z), int(max_z)):
			var world_pos = Vector3(x, 0, z)

			# if not chunk.is_position_in_chunk(world_pos):
			# 	continue

			chunk.set_height_at_world_position(world_pos, structure_data.position.y)
