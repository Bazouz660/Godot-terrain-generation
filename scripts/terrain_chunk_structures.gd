extends Node
class_name TerrainChunkStructures

# This is a helper that you could later extend to work with multiple structures.
static func _apply_deformations(chunk: TerrainChunk) -> void:
	# Assume you have a function to retrieve structures for this chunk.
	# For each structure, call _apply_structure_deformation.
	if chunk.get_structures_in_chunk().is_empty():
		return

	for structure in chunk.get_structures_in_chunk():
		_apply_structure_deformation(chunk, structure)

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

	var center: Vector2 = Vector2((min_x + max_x) / 2, (min_z + max_z) / 2)

	# Sample the base height at the structure's position using the original noise
	var base_height = chunk.get_height_at_world_position(Vector3(center.x, 0, center.y))

	structure_data.position.y = base_height

	# round min_x, max_x, min_z, max_z to the largest nearest integer for positive values and smallest for negative values
	min_x = floor(min_x)
	max_x = ceil(max_x)
	min_z = floor(min_z)
	max_z = ceil(max_z)

	# Apply the deformation to the terrain
	for x in range(int(min_x), int(max_x)):
		for z in range(int(min_z), int(max_z)):
			var world_pos = Vector3(x, 0, z)

			chunk.set_height_at_world_position(world_pos, structure_data.position.y)
