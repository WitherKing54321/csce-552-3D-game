extends CharacterBody3D

# ==================== CONSTANTS ======================
const SPEED: float = 8.0
const RUN_MULT: float = 1.4
const JUMP_VELOCITY: float = 9.0

const MOUSE_SENS: float = 0.005
const TURN_SPEED: float = 10.0

const PITCH_MIN: float = deg_to_rad(-89.0)
const PITCH_MAX: float = deg_to_rad( 89.0)

# Crouch
const CROUCH_SCALE: float = 0.4       # fraction of capsule height while crouched
const CROUCH_SPEED_MULT: float = 0.7
const CROUCH_LERP: float = 12.0       # how fast we lerp crouch state
const CAM_CROUCH_DROP: float = 1.0    # meters camera moves down when fully crouched
const HEADROOM_MARGIN: float = 0.05   # extra space needed to stand up
const CROUCH_DISABLE_SPRINT: bool = true

# Jump “coyote time”
const COYOTE_TIME: float = 0.15

# ==================== NODES ==========================
@onready var pivot_yaw: Node3D       = $PivotYaw
@onready var pivot_pitch: Node3D     = $PivotYaw/PivotPitch
@onready var camera: Camera3D        = $PivotYaw/PivotPitch/Camera3D
@onready var collider: CollisionShape3D = $CollisionShape3D

# ==================== STATE ==========================
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

var yaw: float = 0.0
var pitch: float = 0.0

var _mouse_captured: bool = true
var _time_since_floor: float = 0.0

# crouch
var _is_crouching: bool = false      # desired (input)
var _crouch_t: float = 0.0           # smoothed 0..1
var _cam_base_y: float = 0.0

# capsule data
var _capsule: CapsuleShape3D = null
var _capsule_h_base: float = 0.0
var _capsule_r_base: float = 0.0
var _collider_local_y_base: float = 0.0


# ==================== READY ==========================
func _ready() -> void:
	_capture_mouse()
	_update_view_nodes()

	# cache camera base height
	if pivot_pitch:
		_cam_base_y = pivot_pitch.position.y

	# cache capsule info
	if collider and collider.shape is CapsuleShape3D:
		_capsule = collider.shape
		_capsule_h_base = _capsule.height
		_capsule_r_base = _capsule.radius
		_collider_local_y_base = collider.position.y

	# ======= CHECKPOINT SPAWN =======
	if CheckpointManager.has_checkpoint:
		global_transform = CheckpointManager.get_checkpoint(global_transform)
	else:
		CheckpointManager.set_checkpoint(global_transform)


# ==================== INPUT ==========================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_mouse_captured = not _mouse_captured
		if _mouse_captured:
			_capture_mouse()
		else:
			_release_mouse()

	if _mouse_captured and event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		yaw   -= mm.relative.x * MOUSE_SENS
		pitch -= mm.relative.y * MOUSE_SENS
		pitch = clamp(pitch, PITCH_MIN, PITCH_MAX)
		_update_view_nodes()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and _mouse_captured:
		_capture_mouse()


func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _update_view_nodes() -> void:
	if pivot_yaw:
		pivot_yaw.rotation.y = yaw
	if pivot_pitch:
		pivot_pitch.rotation.x = pitch


# ==================== PHYSICS =========================
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	# Track coyote time
	if is_on_floor():
		_time_since_floor = 0.0
	else:
		_time_since_floor += delta

	# Movement input
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var want_crouch: bool = Input.is_action_pressed("crouch")

	# Sprint
	var sprint_input: bool = Input.is_action_pressed("sprint")
	var can_sprint: bool = (not CROUCH_DISABLE_SPRINT) or (not _is_crouching)
	var is_sprinting: bool = sprint_input and can_sprint

	# Jump
	if Input.is_action_just_pressed("jump"):
		if _time_since_floor <= COYOTE_TIME:
			velocity.y = JUMP_VELOCITY

	# Crouch logic (with headroom check)
	if not want_crouch and _is_crouching:
		if not _has_headroom_to_stand():
			want_crouch = true

	_is_crouching = want_crouch
	var crouch_target: float = (1.0 if _is_crouching else 0.0)
	_crouch_t = lerpf(_crouch_t, crouch_target, clamp(CROUCH_LERP * delta, 0.0, 1.0))

	_apply_crouch_camera(delta)
	_apply_crouch_collider()

	# Direction relative to camera yaw
	var basis := Basis(Vector3.UP, yaw)
	var right: Vector3 = basis.x
	var forward: Vector3 = -basis.z
	var move_dir: Vector3 = (right * move_input.x) + (forward * move_input.y)

	if move_dir.length_squared() > 1e-6:
		move_dir = move_dir.normalized()

	var target_speed: float = SPEED
	if is_sprinting:
		target_speed *= RUN_MULT
	if _is_crouching:
		target_speed *= CROUCH_SPEED_MULT

	var horiz_vel: Vector3 = velocity
	horiz_vel.y = 0.0
	var target_vel: Vector3 = move_dir * target_speed

	var accel := 12.0
	horiz_vel = horiz_vel.lerp(target_vel, clamp(accel * delta, 0.0, 1.0))
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z

	move_and_slide()


# ==================== CROUCH HELPERS ==================
func _apply_crouch_camera(delta: float) -> void:
	if not pivot_pitch:
		return

	var target_y := lerpf(_cam_base_y, _cam_base_y - CAM_CROUCH_DROP, _crouch_t)
	pivot_pitch.position.y = lerpf(pivot_pitch.position.y, target_y, clamp(CROUCH_LERP * delta, 0.0, 1.0))


func _apply_crouch_collider() -> void:
	if not _capsule or not collider:
		return

	var h_target: float = _capsule_h_base * lerpf(1.0, CROUCH_SCALE, _crouch_t)
	_capsule.height = h_target

	# keep feet planted: adjust collider position so bottom stays on ground
	var half_base: float = _capsule_h_base * 0.5
	var half_now: float = _capsule.height * 0.5
	var foot_fix: float = (half_now - half_base)
	collider.position.y = _collider_local_y_base + foot_fix


func _has_headroom_to_stand() -> bool:
	if not _capsule:
		return true

	var origin: Vector3 = global_transform.origin
	var current_half: float = _capsule.height * 0.5
	var stand_half: float   = _capsule_h_base * 0.5

	var from: Vector3 = origin + Vector3.UP * (current_half + _capsule.radius)
	var to:   Vector3 = origin + Vector3.UP * (stand_half + _capsule.radius + HEADROOM_MARGIN)

	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.exclude = [self]

	var hit := space.intersect_ray(params)
	return hit.is_empty()


# ==================== UNUSED SIGNAL STUBS ==============
func _on_retry_button_pressed() -> void:
	pass

func _on_quit_button_pressed() -> void:
	pass

func _on_chase_trigger_body_entered(body: Node3D) -> void:
	pass
