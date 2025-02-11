extends Area3D
class_name Structure

var obb: OBB
@export var mesh: MeshInstance3D

func _ready():
	var aabb := mesh.get_aabb()
	obb = OBB.new(aabb, self)
