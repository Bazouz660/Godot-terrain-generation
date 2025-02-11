extends Camera3D

@export var main_camera: Camera3D
@export var water_plane: MeshInstance3D

func _process(_delta):
    if main_camera and water_plane:
        var main_pos = main_camera.global_transform.origin
        var water_height = water_plane.global_transform.origin.y
        # Mirror main camera's Y position relative to water plane
        var reflected_y = 2 * water_height - main_pos.y
        global_transform.origin = Vector3(main_pos.x, reflected_y, main_pos.z)
        # Mirror rotation (flip pitch)
        look_at(main_camera.global_transform.origin, Vector3.UP)