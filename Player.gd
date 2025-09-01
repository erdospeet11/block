extends CharacterBody3D

# Movement variables
@export var speed = 5.0
@export var jump_velocity = 7.0
@export var mouse_sensitivity = 0.002
@export var flying = false
@export var fly_speed = 10.0

# Camera and head nodes
@onready var head = $Head
@onready var camera = $Head/Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Set initial position above the chunk
	global_position = Vector3(8, 20, 8)

func _input(event):
	# Handle mouse look
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			# Rotate head (pitch)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			
			# Rotate body (yaw)
			rotate_y(-event.relative.x * mouse_sensitivity)
	
	# Toggle flying mode
	if event.is_action_pressed("jump"):  # Space key
		if Input.is_action_pressed("fly_down"):  # Shift key
			flying = !flying
			print("Flying mode: ", flying)

func _physics_process(delta):
	# Handle gravity and flying
	if not flying and not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and (is_on_floor() or flying):
		if flying:
			velocity.y = fly_speed
		elif is_on_floor():
			velocity.y = jump_velocity
	
	# Handle flying down
	if flying and Input.is_action_pressed("fly_down"):
		velocity.y = -fly_speed
	elif flying and not Input.is_action_pressed("jump"):
		velocity.y = 0
	
	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	
	# Calculate movement direction relative to camera
	var direction = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply movement
	var current_speed = fly_speed if flying else speed
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 10)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta * 10)

func _process(delta: float) -> void:
	move_and_slide()
