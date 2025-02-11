extends Marker3D

@export var CAMERA_SENSIVITY = 100.0


func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rotation = get_rotation_degrees()
		#rotation.x -= event.relative.y * CAMERA_SENSIVITY * get_process_delta_time()
		rotation.y -= event.relative.x * CAMERA_SENSIVITY * get_process_delta_time()
		#rotation.x = clamp(rotation.x, -90, 90)
		set_rotation_degrees(rotation)