extends CharacterBody3D

# ==================== CONSTANTS ======================
const SPEED: float = 8.0
const RUN_MULT: float = 1.4
const JUMP_VELOCITY: float = 9.0

const MOUSE_SENS: float = 0.005

const PITCH_MIN: float = deg_to_rad(-89.0)
const PITCH_MAX: float = deg_to_rad(89.0)

# Crouch settings
const CROUCH_SCALE: float = 0.4        # fraction of capsule height while crouched
const CROUCH_SPEED_MULT: float = 0.7
const CAM_CROUCH_DROP: float = 1.3     # meters camera moves down when fully crouched
const HEADROOM_MARGIN: float = 0.05    # extra space needed to stand up
const CROUCH_DISABLE_SPRINT: bool = true
const CROUCH_LERP: float = 10.0        # how fast crouch transitions (bigger = snappier)

# Jump "coyote time"
const COYOTE_TIME: float = 0.15

# ==================== AUDIO CONSTANTS =================

# Streams
const STAND_JUMP_SOUNDS: Array[AudioStream] = [
	preload("res://Sounds/StandingJump1.wav"),
	preload("res://Sounds/StandingJump2.wav")
]

const RUN_JUMP_SOUNDS: Array[AudioStream] = [
	preload("res://Sounds/RunningJump1.wav"),
	preload("res://Sounds/RunningJump2.wav")
]

const WALK_JUMP_SOUNDS: Array[AudioStream] = [
	preload("res://Sounds/WalkingJump1.wav"),
	preload("res://Sounds/WalkingJump2.wav")
]

const WALK_LOOP: AudioStream   = preload("res://Sounds/Walking3D.wav")
const SPRINT_LOOP: AudioStream = preload("res://Sounds/Running3D.wav")

const LAND_SOUNDS: Array[AudioStream] = [
	preload("res://Sounds/Landing.wav")
]

# Volumes in dB (tweak these to balance your mix)
const STAND_JUMP_DB: float  = 0.0
const RUN_JUMP_DB: float    = 0.0
const WALK_JUMP_DB: float   = 0.0
const WALK_LOOP_DB: float   = -4.0
const SPRINT_LOOP_DB: float = -4.0
const LAND_DB: float        = -2.0

# ==================== NODES ==========================
@onready var pivot_yaw: Node3D          = $PivotYaw
@onready var pivot_pitch: Node3D        = $PivotYaw/PivotPitch
@onready var camera: Camera3D           = $PivotYaw/PivotPitch/Camera3D
@onready var collider: CollisionShape3D = $CollisionShape3D

# ==================== STATE ==========================
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

var yaw: float = 0.0
var pitch: float = 0.0

var _mouse_captured: bool = true
var _time_since_floor: float = 0.0

# Crouch state
var _is_crouching: bool = false    # desired (input)
var _crouch_t: float = 0.0         # smoothed 0..1
var _cam_base_y: float = 0.0

# Capsule data for crouch height scaling
var _capsule: CapsuleShape3D = null
var _capsule_h_base: float = 0.0
var _capsule_r_base: float = 0.0
var _collider_local_y_base: float = 0.0

# Audio players
var _jump_player: AudioStreamPlayer3D
var _step_player: AudioStreamPlayer3D
var _land_player: AudioStreamPlayer3D

var _was_on_floor: bool = false
var _is_sprinting_cached: bool = false

# ==================== READY ==========================
func _ready() -> void:
	randomize()

	# Let other scenes (torch) find this as "player"
	add_to_group("player")

	# Initialize yaw/pitch from whatever orientation the scene / spawn gives us.
	if pivot_yaw:
		yaw = pivot_yaw.rotation.y
	if pivot_pitch:
		pitch = pivot_pitch.rotation.x

	_capture_mouse()
	_update_view_nodes()

	# Cache camera base height
	if pivot_pitch:
		_cam_base_y = pivot_pitch.position.y

	# Cache capsule info for crouch
	if collider and collider.shape is CapsuleShape3D:
		_capsule = collider.shape as CapsuleShape3D
		_capsule_h_base = _capsule.height
		_capsule_r_base = _capsule.radius
		_collider_local_y_base = collider.position.y

	# Audio players
	_jump_player = AudioStreamPlayer3D.new()
	add_child(_jump_player)

	_step_player = AudioStreamPlayer3D.new()
	_step_player.autoplay = false
	add_child(_step_player)

	_land_player = AudioStreamPlayer3D.new()
	add_child(_land_player)

	# ======= CHECKPOINT SPAWN =======
	if CheckpointManager.has_checkpoint:
		global_transform = CheckpointManager.get_checkpoint(global_transform)
	else:
		CheckpointManager.set_checkpoint(global_transform)

# ==================== INPUT ==========================
func _input(event: InputEvent) -> void:
	# Toggle mouse capture (pause, menu, etc.)
	if event.is_action_pressed("ui_cancel"):
		_mouse_captured = not _mouse_captured
		if _mouse_captured:
			_capture_mouse()
		else:
			_release_mouse()

	# Mouse look
	if _mouse_captured and event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		yaw   -= mm.relative.x * MOUSE_SENS
		pitch -= mm.relative.y * MOUSE_SENS
		pitch = clamp(pitch, PITCH_MIN, PITCH_MAX)
		_update_view_nodes()

# ==================== VIEW HELPERS ====================
func _update_view_nodes() -> void:
	if pivot_yaw:
		pivot_yaw.rotation.y = yaw
	if pivot_pitch:
		pivot_pitch.rotation.x = pitch

func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ==================== AUDIO HELPERS ===================
func _play_random(player: AudioStreamPlayer3D, sounds: Array[AudioStream], volume_db: float) -> void:
	if sounds.is_empty():
		return
	var idx := randi() % sounds.size()
	player.stream = sounds[idx]
	player.volume_db = volume_db
	player.play()

# ==================== PHYSICS =========================
func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()

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
	var want_crouch: bool = Input.is_action_pressed("move_crouch")

	# Sprint
	var sprint_input: bool = Input.is_action_pressed("move_sprint")
	var can_sprint: bool = (not CROUCH_DISABLE_SPRINT) or (not _is_crouching)
	var is_sprinting: bool = sprint_input and can_sprint
	_is_sprinting_cached = is_sprinting

	# Jump with coyote time and different sounds
	if Input.is_action_just_pressed("move_jump"):
		if _time_since_floor <= COYOTE_TIME:
			var horiz_speed := Vector2(velocity.x, velocity.z).length()
			var sounds: Array[AudioStream] = STAND_JUMP_SOUNDS
			var volume_db := STAND_JUMP_DB

			if horiz_speed > SPEED * 0.9:
				sounds = RUN_JUMP_SOUNDS
				volume_db = RUN_JUMP_DB
			elif horiz_speed > 0.1:
				sounds = WALK_JUMP_SOUNDS
				volume_db = WALK_JUMP_DB

			_play_random(_jump_player, sounds, volume_db)
			velocity.y = JUMP_VELOCITY

	# Crouch logic with headroom check
	if not want_crouch and _is_crouching:
		# Trying to stand up -> check headroom
		if not _has_headroom_to_stand():
			want_crouch = true

	_is_crouching = want_crouch
	var crouch_target: float = (1.0 if _is_crouching else 0.0)
	_crouch_t = lerpf(_crouch_t, crouch_target, clamp(CROUCH_LERP * delta, 0.0, 1.0))

	_apply_crouch_camera()
	_apply_crouch_collider()

	# -------- MOVEMENT DIRECTION (CAMERA-RELATIVE) ----------
	var basis: Basis
	if pivot_yaw:
		basis = pivot_yaw.global_transform.basis
	else:
		basis = global_transform.basis

	var right: Vector3 = basis.x
	var forward: Vector3 = -basis.z  # Godot forward is -Z

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

	# Post movement state
	var on_floor_now := is_on_floor()

	# Landing sound when we just hit the floor
	if on_floor_now and not was_on_floor:
		_play_random(_land_player, LAND_SOUNDS, LAND_DB)

	# Footstep loops (walk vs sprint)
	var horiz_speed_now := Vector2(velocity.x, velocity.z).length()
	var moving_on_ground := on_floor_now and horiz_speed_now > 0.1

	if moving_on_ground:
		var wanted_stream: AudioStream = WALK_LOOP
		var wanted_db: float = WALK_LOOP_DB

		if _is_sprinting_cached:
			wanted_stream = SPRINT_LOOP
			wanted_db = SPRINT_LOOP_DB

		if _step_player.stream != wanted_stream:
			_step_player.stream = wanted_stream
			_step_player.volume_db = wanted_db
			_step_player.play()
		else:
			_step_player.volume_db = wanted_db
			if not _step_player.playing:
				_step_player.play()
	else:
		if _step_player.playing:
			_step_player.stop()

	_was_on_floor = on_floor_now

# ==================== CROUCH HELPERS ==================
func _apply_crouch_camera() -> void:
	if not pivot_pitch:
		return

	# Move camera down when crouched
	var offset := CAM_CROUCH_DROP * _crouch_t
	var local_pos := pivot_pitch.position
	local_pos.y = _cam_base_y - offset
	pivot_pitch.position = local_pos

func _apply_crouch_collider() -> void:
	if not collider or _capsule == null:
		return

	# Scale capsule height
	var t := _crouch_t
	var new_height := lerpf(_capsule_h_base, _capsule_h_base * CROUCH_SCALE, t)
	_capsule.height = new_height

	# Adjust collider local Y so feet stay on the ground
	var stand_half := _capsule_h_base * 0.5
	var crouch_half := new_height * 0.5
	var offset_y := (stand_half - crouch_half)
	var pos := collider.position
	pos.y = _collider_local_y_base - offset_y
	collider.position = pos

func _has_headroom_to_stand() -> bool:
	# Simple ray check above the player's head to see if there is space to stand
	if not collider:
		return true

	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = global_transform.origin
	var to: Vector3 = from + Vector3.UP * (_capsule_h_base * (1.0 - CROUCH_SCALE) + HEADROOM_MARGIN)

	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.exclude = [self]

	var hit := space_state.intersect_ray(params)
	return hit.is_empty()

# ==================== UNUSED SIGNAL STUBS =============
func _on_retry_button_pressed() -> void:
	pass

func _on_quit_button_pressed() -> void:
	pass

func _on_chase_trigger_body_entered(body: Node3D) -> void:
	pass


func _on_main_menu_pressed() -> void:
	pass # Replace with function body.


func _on_guide_trigger_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
