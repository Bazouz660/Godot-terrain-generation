# StructureManager.gd
extends Node3D
class_name StructureManager

# Global array to hold all structure data (StructureData instances)
static var global_structures: Array[StructureData] = []
static var structure_scene: PackedScene = preload("res://structures/house.tscn")

func generate_random_structure() -> void:
	var structure_instance := structure_scene.instantiate() as Structure
	structure_instance.position = Vector3(randf_range(-100, 100), 0, randf_range(-100, 100))
	var height = TerrainChunkNoise.sample_height(structure_instance.position.x, structure_instance.position.z)
	structure_instance.position.y = height
	structure_instance.rotation_degrees = Vector3(0, randf_range(0, 360), 0)
	add_child(structure_instance)
	structure_instance._generate_data()

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
