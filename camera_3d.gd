extends CharacterBody3D

@export var BASE_SPEED = 5.0
@export var SPRINT_SPEED = 10.0
@export var CAMERA_SENSIVITY = 100.0

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

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rotation = get_rotation_degrees()
		rotation.x -= event.relative.y * CAMERA_SENSIVITY * get_process_delta_time()
		rotation.y -= event.relative.x * CAMERA_SENSIVITY * get_process_delta_time()
		rotation.x = clamp(rotation.x, -90, 90)
		set_rotation_degrees(rotation)


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

	velocity = transform.basis * direction.normalized() * speed

	if Input.is_action_pressed("up"):
		velocity.y = speed
	if Input.is_action_pressed("down"):
		velocity.y = -speed

	move_and_slide()
