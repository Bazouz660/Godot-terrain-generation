@tool
extends Area3D
class_name Structure

@export var mesh: MeshInstance3D
@export var data: StructureData
@export_tool_button("Generate Data", "Callable")
var print_action = _generate_data.bind()

func _ready():
	_generate_data()

func _generate_data(_stupid_placeholder = ""):
	var aabb := mesh.global_transform * mesh.get_aabb()
	data = StructureData.new()
	data.size = aabb.size
	data.position = aabb.position
	data.local_pos = aabb.position - global_transform.origin
