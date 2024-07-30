extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var model = $GobotSkin
@onready var camera = $Camera3D
@onready var camera_origin = $CameraOrigin

# Local Variables
var speed = SPEED
var cam_turn = 0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _input(event):
	if Input.is_action_pressed("Camera Turn") and event is InputEventMouseMotion:
		cam_turn += -event.relative.x * 0.01

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Input.is_action_pressed("Sprint"):
		speed = SPEED * 2
	else:
		speed = SPEED

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Move Left", "Move Right", "Move Forward", "Move Backward")
	var rotate_vector = Vector3(1,1,1).rotated(Vector3(0,1,0), cam_turn)
	var direction = (transform.basis.rotated(Vector3(0,1,0), cam_turn) * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	# Rotate mesh based on movement
	if direction:
		if direction.x > 0:
			model.rotation.y = PI/2
		if direction.x < 0:
			model.rotation.y = -PI/2
		if direction.z < 0:
			model.rotation.y = PI
		if direction.z > 0:
			model.rotation.y = 0
		
	camera_origin.rotation.y = cam_turn
	if direction:
		var angle = atan2(velocity.x, velocity.z)
		model.rotation.y = angle
		
	# Change animation
	if (direction.x != 0 or direction.z != 0) and is_on_floor():
		model.run()
	elif direction.x == 0 and direction.z == 0 and is_on_floor():
		model.idle()
	elif !is_on_floor():
		model.jump()

	move_and_slide()
