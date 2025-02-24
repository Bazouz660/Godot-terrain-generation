# StructureManager.gd
extends Node3D
class_name StructureManager

# Global array to hold all structure data (StructureData instances)
static var global_structures: Array[StructureData] = []
static var structure_scene: PackedScene = preload("res://structures/house.tscn")

func generate_random_structure() -> void:
	var structure_instance := structure_scene.instantiate() as Structure
	structure_instance.position = Vector3(randf_range(-300, 300), 0, randf_range(-300, 300))
	var height = TerrainChunkNoise.sample_height(structure_instance.position.x, structure_instance.position.z)
	structure_instance.position.y = height
	structure_instance.rotation_degrees = Vector3(0, randf_range(0, 360), 0)
	add_child(structure_instance)
	structure_instance._generate_data()

	var aabb = AABB(structure_instance.data.position, structure_instance.data.size)
	print("Can place structure: ", can_place_structure(aabb))
	print("Structure position: ", structure_instance.data.position)
	print("Structure size: ", structure_instance.data.size)

	if !can_place_structure(aabb):
		structure_instance.queue_free()
	else:
		StructureManager.register_structure(structure_instance.data)

# # returns the average steepness of the terrain within
# func _check_terrain_steepness(aabb: AABB) -> float:
# 	var total_steepness = 0.0
# 	var total_points = 0
# 	for x in range(int(aabb.position.x), int(aabb.position.x + aabb.size.x)):
# 		for z in range(int(aabb.position.z), int(aabb.position.z + aabb.size.z)):
# 			var world_pos = Vector3(x, 0, z)
# 			var height = TerrainChunkNoise.sample_height(world_pos.x, world_pos.z)
# 			var normal = TerrainChunkNoise.sample_normal(world_pos.x, world_pos.z)
# 			var steepness = normal.angle_to(Vector3(0, 1, 0))
# 			total_steepness += steepness
# 			total_points += 1
# 	return total_steepness / total_points

static func register_structure(structure_data: StructureData) -> void:
	# Add structure data if not already present.
	if not global_structures.has(structure_data):
		global_structures.append(structure_data)

static func unregister_structure(structure_data: StructureData) -> void:
	global_structures.erase(structure_data)

# Returns an array of StructureData that intersect the given AABB.
static func get_structures_in_area(area: AABB) -> Array[StructureData]:
	var result: Array[StructureData] = []
	for structure_data in global_structures:
		var struct_aabb = AABB(structure_data.position, structure_data.size)
		if area.intersects(struct_aabb):
			result.append(structure_data)
	return result


static func can_place_structure(new_aabb: AABB) -> bool:
	# Iterate through already registered structures.
	for structure_data in global_structures:
		var existing_aabb = AABB(structure_data.position, structure_data.size)
		if new_aabb.intersects(existing_aabb):
			return false
	return true
