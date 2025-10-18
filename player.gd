extends CharacterBody3D

# ============================================================
# === MOVEMENT & CAMERA CONSTANTS =============================
# ============================================================
const SPEED: float = 7.0
const JUMP_VELOCITY: float = 5.0
const PITCH_MIN: float = deg_to_rad(-80.0)
const PITCH_MAX: float = deg_to_rad(-10.0)
const MOUSE_SENS: float = 0.005
const TURN_SPEED: float = 8.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float
var rotating_camera := false
var yaw := 0.0
var pitch := -0.35
var last_move_dir := Vector3.FORWARD

# ============================================================
# === ANIMATION ===============================================
# ============================================================
var walk_phase := 0.0
const WALK_FREQ := 6.0
const ARM_SWING_DEG := 35.0
const LEG_SWING_DEG := 28.0
const BOB_HEIGHT := 0.04
const AIR_MULT := 0.35

@onready var visual: Node3D = $Body
@onready var l_arm_pivot: Node3D = $Body/LArmPivot
@onready var r_arm_pivot: Node3D = $Body/RArmPivot
@onready var l_leg_pivot: Node3D = $Body/LLegPivot
@onready var r_leg_pivot: Node3D = $Body/RLegPivot
@onready var torso: MeshInstance3D = $Body/Torso
@onready var spring_arm: SpringArm3D = $SpringArm
var torso_base_y := 0.0

# ============================================================
# === COMBAT / SWORD EQUIPMENT ================================
# ============================================================
@export var base_attack_damage := 1
@export var weapon_socket_path := NodePath("Body/RArmPivot/HandSocket")
@export var hold_rot_deg_right := Vector3(-80, 10, 0)
@export var hold_blend_speed := 10.0

# The sword scene you currently have
@export var first_sword_scene: PackedScene = preload("res://items/swords/first_sword.tscn")

var _weapon_socket: Node3D
var current_sword: SwordItem
var owned_swords: Array[PackedScene] = []
var sword_index: int = -1

# ============================================================
# === INITIALIZATION ==========================================
# ============================================================
func _ready() -> void:
	torso_base_y = torso.position.y
	_update_spring_arm()
	_weapon_socket = get_node_or_null(weapon_socket_path)
	print("Player ready. Socket:", _weapon_socket)

# ============================================================
# === COMBAT / EQUIP HELPERS =================================
# ============================================================
func get_attack_damage() -> int:
	return base_attack_damage + (current_sword.bonus_damage if current_sword else 0)

func equip_sword_scene(sword_scene: PackedScene) -> void:
	if sword_scene == null:
		push_warning("equip_sword_scene: sword_scene is null")
		return
	unequip_sword()

	var inst := sword_scene.instantiate()
	if inst is SwordItem:
		current_sword = inst
	else:
		push_warning("Sword scene missing SwordItem.gd; still attaching.")
		current_sword = null

	if _weapon_socket:
		_weapon_socket.add_child(inst)
		if inst is SwordItem:
			inst.position = inst.grip_position
			inst.rotation_degrees = inst.grip_rotation_deg
			inst.scale = inst.grip_scale
			inst.on_equipped(self)
	print("Equipped:", (current_sword.sword_name if current_sword else inst.name))

func unequip_sword() -> void:
	if current_sword and is_instance_valid(current_sword):
		current_sword.on_unequipped(self)
		current_sword.queue_free()
	current_sword = null

# === Inventory functions ===
func add_sword_to_inventory(scene: PackedScene, auto_equip := true) -> void:
	if scene == null:
		return
	owned_swords.append(scene)
	if auto_equip:
		sword_index = owned_swords.size() - 1
		equip_sword_scene(scene)
	print("Added sword to inventory. Total:", owned_swords.size())

func cycle_next_sword() -> void:
	if owned_swords.is_empty():
		return
	sword_index = (sword_index + 1) % owned_swords.size()
	equip_sword_scene(owned_swords[sword_index])
	print("Swapped to sword index:", sword_index)

# ============================================================
# === CAMERA INPUT ============================================
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		rotating_camera = event.pressed
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if rotating_camera else Input.MOUSE_MODE_VISIBLE)

	if rotating_camera and event is InputEventMouseMotion:
		yaw   -= event.relative.x * MOUSE_SENS
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, PITCH_MIN, PITCH_MAX)
		_update_spring_arm()

	# --- EQUIP/UNEQUIP with E ---
	if event.is_action_pressed("interact"):
		if current_sword == null:
			print("Equipping first sword...")
			add_sword_to_inventory(first_sword_scene, true)
		else:
			print("Unequipping current sword...")
			unequip_sword()

	# --- CYCLE with weapon_next (optional key) ---
	if event.is_action_pressed("weapon_next"):
		cycle_next_sword()

func _update_spring_arm() -> void:
	spring_arm.rotation = Vector3(pitch, yaw, 0)

# ============================================================
# === MOVEMENT & ANIMATION ===================================
# ============================================================
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = -0.1

	# Input
	var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var yaw_basis := Basis(Vector3.UP, yaw)
	var cam_right := yaw_basis.x.normalized()
	var cam_forward := (-yaw_basis.z).normalized()
	var move_dir := (cam_right * input_vec.x) + (cam_forward * input_vec.y)

	if move_dir.length() > 0.001:
		move_dir = move_dir.normalized()
		last_move_dir = move_dir
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	# Face direction
	if last_move_dir.length() > 0.001:
		var target_yaw := atan2(last_move_dir.x, last_move_dir.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, TURN_SPEED * delta)

	# Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Walk animation & sword pose
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	var moving := horiz_speed > 0.1
	var speed_norm: float = clamp(horiz_speed / SPEED, 0.0, 1.0)
	var phase_mult: float = (1.0 if is_on_floor() else AIR_MULT)

	if moving:
		walk_phase += delta * WALK_FREQ * (0.5 + 0.5 * speed_norm)
		var s := sin(walk_phase)
		var arm_amt: float = deg_to_rad(ARM_SWING_DEG) * speed_norm * phase_mult
		var leg_amt: float = deg_to_rad(LEG_SWING_DEG) * speed_norm * phase_mult

		# Arms
		l_arm_pivot.rotation.x = s * arm_amt
		if current_sword:
			var target := hold_rot_deg_right * (PI / 180.0)
			r_arm_pivot.rotation.x = lerp(r_arm_pivot.rotation.x, target.x, hold_blend_speed * delta)
			r_arm_pivot.rotation.y = lerp(r_arm_pivot.rotation.y, target.y, hold_blend_speed * delta)
			r_arm_pivot.rotation.z = lerp(r_arm_pivot.rotation.z, target.z, hold_blend_speed * delta)
		else:
			r_arm_pivot.rotation.x = -s * arm_amt

		# Legs
		l_leg_pivot.rotation.x = -s * leg_amt
		r_leg_pivot.rotation.x =  s * leg_amt

		torso.position.y = torso_base_y + abs(s) * BOB_HEIGHT
	else:
		l_arm_pivot.rotation.x = lerp(l_arm_pivot.rotation.x, 0.0, 10 * delta)
		r_arm_pivot.rotation.x = lerp(r_arm_pivot.rotation.x, 0.0, 10 * delta)
		l_leg_pivot.rotation.x = lerp(l_leg_pivot.rotation.x, 0.0, 10 * delta)
		r_leg_pivot.rotation.x = lerp(r_leg_pivot.rotation.x, 0.0, 10 * delta)
		torso.position.y = lerp(torso.position.y, torso_base_y, 10 * delta)

	move_and_slide()
