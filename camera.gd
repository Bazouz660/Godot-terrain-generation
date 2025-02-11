extends CharacterBody3D

@export var BASE_SPEED = 5.0
@export var SPRINT_SPEED = 10.0
@export var CAMERA_SENSIVITY = 100.0

@onready var reflection_camera = %ReflectionCamera
@onready var water_plane = %WaterPlane

var speed = BASE_SPEED

func _ready():
	#get_viewport().debug_draw = Viewport.DebugDraw.DEBUG_DRAW_WIREFRAME
	pass

func _input(event: InputEvent):
	if event is InputEventKey and event.keycode == KEY_0:
		print("Debug draw: ", get_viewport().debug_draw)
		get_viewport().debug_draw = Viewport.DebugDraw.DEBUG_DRAW_WIREFRAME
	elif event is InputEventKey and event.keycode == KEY_9:
		get_viewport().debug_draw = Viewport.DebugDraw.DEBUG_DRAW_DISABLED


func _physics_process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# get the relative mouse motion
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = BASE_SPEED

	velocity = Vector3.ZERO

	var direction = Vector3.ZERO
	if Input.is_action_pressed("forward"):
		direction.z -= 1
	if Input.is_action_pressed("back"):
		direction.z += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1

	velocity = direction.normalized() * speed

	if Input.is_action_pressed("up"):
		velocity.y = speed
	if Input.is_action_pressed("down"):
		velocity.y = -speed

	move_and_slide()

func _process(delta):
	var main_camera = %MainCamera
	var camera_pivot = %CameraPivot


	# compute how much we are facing in the XZ plane
	var z_facing = -cos(main_camera.global_rotation.y)
	var x_facing = sin(main_camera.global_rotation.y)

	var half_pi = PI / 2

	var incidence = half_pi - (-camera_pivot.rotation.x)
	incidence *= 0.5

	#print("incidence: ", incidence)


	# Mirror position across water plane (Y=0)
	reflection_camera.rotation.y = -deg_to_rad(-45) * x_facing * 0.3
	reflection_camera.rotation.x = -deg_to_rad(-45) * z_facing * 0.3

	var target_position_x = global_position.x
	var target_position_z = global_position.z


	water_plane.global_position.x = target_position_x
	water_plane.global_position.z = target_position_z
	reflection_camera.global_position.x = target_position_x
	reflection_camera.global_position.z = target_position_z
