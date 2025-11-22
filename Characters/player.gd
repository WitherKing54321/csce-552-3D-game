extends CharacterBody3D

# ============================================================
# === MOVEMENT & CAMERA CONSTANTS =============================
# ============================================================
const SPEED: float = 7.0                  # base walk speed
const JUMP_VELOCITY: float = 9.0
@export var RUN_MULT: float = 1.4         # 30% faster while sprinting

# Crouch tuning
const CROUCH_SCALE: float = 0.40          # visual scale while crouched
const CROUCH_SPEED_MULT: float = 0.70     # speed multiplier while crouched
const CROUCH_LERP: float = 12.0           # higher = snappier transitions
const CAM_CROUCH_DROP: float = 0.9       # how much to lower the FP camera (meters)
const HEADROOM_MARGIN: float = 0.05       # extra space required to stand
const CROUCH_DISABLE_SPRINT: bool = true  # don't allow sprint while crouched

# First-person look clamps
const PITCH_MIN: float = deg_to_rad(-89.0)
const PITCH_MAX: float = deg_to_rad( 89.0)

# Mouse sensitivity (tune to taste)
@export var MOUSE_SENS: float = 0.005
@export var TURN_SPEED: float = 12.0  # how fast the visible body lerps to face camera

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float
var yaw: float = 0.0
var pitch: float = 0.0

# ============================================================
# === ANIMATION ===============================================
# ============================================================
var walk_phase: float = 0.0
const WALK_FREQ := 6.0
const ARM_SWING_DEG := 35.0
const LEG_SWING_DEG := 28.0
const BOB_HEIGHT := 0.04
const AIR_MULT := 0.35

# Additive crouch pose
const CROUCH_KNEE_DEG := 28.0            # knee bend
const CROUCH_TORSO_DEG := -10.0          # slight hunch (negative pitches forward)
const CROUCH_ARM_DEG  := 10.0            # arms forward a bit

@onready var visual: Node3D = $Body
@onready var l_arm_pivot: Node3D = $Body/LArmPivot
@onready var r_arm_pivot: Node3D = $Body/RArmPivot
@onready var l_leg_pivot: Node3D = $Body/LLegPivot
@onready var r_leg_pivot: Node3D = $Body/RLegPivot
@onready var torso: MeshInstance3D = $Body/Torso

@onready var spring_arm: SpringArm3D = get_node_or_null("SpringArm")

# === First-person camera nodes =======
@onready var fp_pivot_yaw: Node3D   = get_node_or_null("PivotYaw")
@onready var fp_pivot_pitch: Node3D = get_node_or_null("PivotYaw/PivotPitch")
@onready var fp_camera: Camera3D    = get_node_or_null("PivotYaw/PivotPitch/Camera3D")

# Optional collider (will auto-adjust if it's a CapsuleShape3D)
@onready var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")

var torso_base_y: float = 0.0
var _mouse_captured: bool = true

# Crouch state
var _is_crouching: bool = false                # requested (input)
var _crouch_t: float = 0.0                     # smoothed 0..1
var _visual_base_scale: Vector3
var _cam_base_y: float = 0.0

# Capsule collider cached data (if present)
var _capsule: CapsuleShape3D = null
var _capsule_h_base: float = 0.0
var _capsule_r_base: float = 0.0
var _collider_local_y_base: float = 0.0

# ============================================================
# === INITIALIZATION ==========================================
# ============================================================
func _ready() -> void:
	_capture_mouse()
	torso_base_y = torso.position.y
	_update_view_nodes()

	_visual_base_scale = visual.scale
	if fp_pivot_pitch:
		_cam_base_y = fp_pivot_pitch.position.y

	# cache collider info if possible
	if collider and collider.shape is CapsuleShape3D:
		_capsule = collider.shape
		_capsule_h_base = _capsule.height
		_capsule_r_base = _capsule.radius
		_collider_local_y_base = collider.position.y

	if spring_arm:
		spring_arm.visible = false
		spring_arm.set_process(false)

# ============================================================
# === INPUT ===================================================
# ============================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_mouse_captured = not _mouse_captured
		if _mouse_captured: _capture_mouse()
		else: _release_mouse()

	if _mouse_captured and event is InputEventMouseMotion:
		yaw   -= event.relative.x * MOUSE_SENS
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, PITCH_MIN, PITCH_MAX)
		_update_view_nodes()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and _mouse_captured:
		_capture_mouse()

func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _update_view_nodes() -> void:
	if fp_pivot_yaw:   fp_pivot_yaw.rotation.y = yaw
	if fp_pivot_pitch: fp_pivot_pitch.rotation.x = pitch

# ============================================================
# === MOVEMENT & ANIMATION ===================================
# ============================================================
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	# Crouch input/state (hold)
	var want_crouch: bool = Input.is_action_pressed("move_crouch")
	if not want_crouch and _is_crouching:
		# trying to stand: check headroom if we shrank a capsule
		if _capsule and not _has_headroom_to_stand():
			want_crouch = true  # stay crouched under low ceiling

	_is_crouching = want_crouch
	var crouch_target: float = (1.0 if _is_crouching else 0.0)
	_crouch_t = lerpf(_crouch_t, crouch_target, clamp(CROUCH_LERP * delta, 0.0, 1.0))

	_apply_crouch_visuals(delta)
	_apply_crouch_collider()

	# WASD relative to camera yaw
	var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var yaw_basis := Basis(Vector3.UP, yaw)
	var cam_right := yaw_basis.x
	var cam_forward := -yaw_basis.z
	var move_dir := (cam_right * input_vec.x) + (cam_forward * input_vec.y)

	# Sprint state (optionally disabled while crouching)
	var wants_move: bool = move_dir.length_squared() > 0.0001
	var sprint_allowed: bool = (not CROUCH_DISABLE_SPRINT) or (_crouch_t < 0.1)
	var is_sprinting: bool = wants_move and sprint_allowed and Input.is_action_pressed("move_sprint")
	var target_speed: float = SPEED * (RUN_MULT if is_sprinting else 1.0)
	target_speed *= lerpf(1.0, CROUCH_SPEED_MULT, _crouch_t)

	if wants_move:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * target_speed
		velocity.z = move_dir.z * target_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	# Jump (no jump boost while crouched)
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		# optional: prevent jumping while crouched; comment out to allow
		if _crouch_t < 0.5:
			velocity.y = JUMP_VELOCITY

	# Face camera
	var target_yaw: float = yaw
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, TURN_SPEED * delta)

	# Walk animation (normalized by current target speed so pacing looks right while sprinting)
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	var moving: bool = horiz_speed > 0.1
	var speed_norm: float = (horiz_speed / max(0.001, target_speed))
	speed_norm = clamp(speed_norm, 0.0, 1.0)
	var phase_mult: float = (1.0 if is_on_floor() else AIR_MULT)

	# Base crouch pose (additive)
	var knee_add: float = deg_to_rad(-CROUCH_KNEE_DEG) * _crouch_t
	var arm_add: float  = deg_to_rad( CROUCH_ARM_DEG ) * _crouch_t
	var torso_add: float = deg_to_rad(CROUCH_TORSO_DEG) * _crouch_t

	if moving:
		walk_phase += delta * WALK_FREQ * (0.5 + 0.5 * speed_norm) * (1.0 - 0.35 * _crouch_t)
		var s := sin(walk_phase)
		var arm_amt: float = deg_to_rad(ARM_SWING_DEG) * speed_norm * phase_mult * (1.0 - 0.5 * _crouch_t)
		var leg_amt: float = deg_to_rad(LEG_SWING_DEG) * speed_norm * phase_mult * (1.0 - 0.5 * _crouch_t)

		l_arm_pivot.rotation.x =  s * arm_amt + arm_add
		r_arm_pivot.rotation.x = -s * arm_amt + arm_add
		l_leg_pivot.rotation.x = -s * leg_amt + knee_add
		r_leg_pivot.rotation.x =  s * leg_amt + knee_add
		torso.position.y = torso_base_y + abs(s) * BOB_HEIGHT * (1.0 - 0.5 * _crouch_t)
	else:
		l_arm_pivot.rotation.x = lerpf(l_arm_pivot.rotation.x, arm_add, 10.0 * delta)
		r_arm_pivot.rotation.x = lerpf(r_arm_pivot.rotation.x, arm_add, 10.0 * delta)
		l_leg_pivot.rotation.x = lerpf(l_leg_pivot.rotation.x, knee_add, 10.0 * delta)
		r_leg_pivot.rotation.x = lerpf(r_leg_pivot.rotation.x, knee_add, 10.0 * delta)
		torso.position.y = lerpf(torso.position.y, torso_base_y, 10.0 * delta)

	# small torso hunch while crouched
	visual.rotation.x = lerpf(visual.rotation.x, torso_add, 10.0 * delta)

	move_and_slide()

# ============================================================
# === CROUCH HELPERS =========================================
# ============================================================
func _apply_crouch_visuals(delta: float) -> void:
	# Visual scale
	var target_scale: Vector3 = _visual_base_scale.lerp(_visual_base_scale * CROUCH_SCALE, _crouch_t)
	visual.scale = visual.scale.lerp(target_scale, clamp(CROUCH_LERP * delta, 0.0, 1.0))

	# Camera drop (first-person)
	if fp_pivot_pitch:
		var target_y: float = lerpf(_cam_base_y, _cam_base_y - CAM_CROUCH_DROP, _crouch_t)
		fp_pivot_pitch.position.y = lerpf(fp_pivot_pitch.position.y, target_y, clamp(CROUCH_LERP * delta, 0.0, 1.0))

func _apply_crouch_collider() -> void:
	# Only if we found a CapsuleShape3D
	if not _capsule:
		return

	# Target capsule height (radius stays the same to avoid foot clipping)
	var h_target: float = _capsule_h_base * lerpf(1.0, CROUCH_SCALE, _crouch_t)
	if absf(_capsule.height - h_target) > 0.002:
		_capsule.height = h_target

	# Keep the feet planted: move the collision node so bottom sits at the ground
	var half_h_base: float = _capsule_h_base * 0.5
	var half_h_now: float = _capsule.height * 0.5
	var foot_fix: float = (half_h_now - half_h_base)
	collider.position.y = _collider_local_y_base + foot_fix

func _has_headroom_to_stand() -> bool:
	# If no capsule, assume it's okay
	if not _capsule:
		return true

	# Ray upward to see if there's space to stand
	var origin: Vector3 = global_transform.origin
	var current_half: float = _capsule.height * 0.5
	var stand_half: float = _capsule_h_base * 0.5

	var from: Vector3 = origin + Vector3.UP * (current_half + _capsule.radius)
	var to: Vector3   = origin + Vector3.UP * (stand_half + _capsule.radius + HEADROOM_MARGIN)

	var space := get_world_3d().direct_space_state
	var p := PhysicsRayQueryParameters3D.create(from, to)
	p.exclude = [self]
	var hit := space.intersect_ray(p)
	return hit.is_empty()


func _on_retry_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	pass # Replace with function body.


func _on_chase_trigger_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
