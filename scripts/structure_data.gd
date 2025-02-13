extends Resource
class_name StructureData

@export var size: Vector3 = Vector3.ZERO

@export var position: Vector3 = Vector3.ZERO
@export var local_pos: Vector3 = Vector3.ZERO

func _to_string():
    return "size: %s, position: %s" % [size, position]
