extends Camera3D

var mouse_sensitivity := 0.002
var move_speed := 10.0
var fast_speed := 40.0
var slow_speed := 3.0

var velocity := Vector3.ZERO
var input_dir := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	yaw = rotation.y
	pitch = rotation.x

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_yaw_pitch(event.relative)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _yaw_pitch(relative):
	yaw -= relative.x * mouse_sensitivity
	pitch -= relative.y * mouse_sensitivity
	pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	rotation = Vector3(pitch, yaw, 0)

func _process(delta):
	_handle_input()
	var speed = move_speed
	if Input.is_action_pressed("shift"):
		speed = fast_speed
	elif Input.is_action_pressed("ctrl"):
		speed = slow_speed
	velocity = (transform.basis * input_dir).normalized() * speed
	position += velocity * delta

func _handle_input():
	input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_page_up"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_page_down"):
		input_dir.y -= 1
