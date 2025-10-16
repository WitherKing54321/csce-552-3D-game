extends CharacterBody3D

const SPEED := 7.0
const JUMP_VELOCITY := 5.0
const PITCH_MIN := deg_to_rad(-80.0)
const PITCH_MAX := deg_to_rad(-10.0)
const MOUSE_SENS := 0.005

var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float
var rotating_camera := false
var yaw := 0.0
var pitch := -0.35

@onready var spring_arm: SpringArm3D = $SpringArm

func _ready() -> void:
	_update_spring_arm()

func _unhandled_input(event: InputEvent) -> void:
	# Right mouse pressed/released → start/stop rotating
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		rotating_camera = event.pressed
		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED if rotating_camera else Input.MOUSE_MODE_VISIBLE
		) # ← fixed ternary

	# Rotate while right mouse is held
	if rotating_camera and event is InputEventMouseMotion:
		yaw   -= event.relative.x * MOUSE_SENS
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, PITCH_MIN, PITCH_MAX)
		_update_spring_arm()

func _update_spring_arm() -> void:
	spring_arm.rotation = Vector3(pitch, yaw, 0.0)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	# World-space movement (camera doesn’t affect direction)
	var input_vec: Vector2 = Input.get_vector("move_right", "move_left", "move_forward", "move_backward")
	var direction := Vector3(input_vec.x, 0.0, -input_vec.y)

	if direction.length() > 0.001:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	# Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
