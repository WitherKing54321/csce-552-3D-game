extends Node3D
class_name FlashPane

@export var base_interval: float = 8.0
@export var interval_jitter: float = 2.0

static var _master: FlashPane = null
static var _instances: Array[FlashPane] = []

var _meshes: Array[MeshInstance3D] = []
var _lights: Array[Light3D] = []
var _rng := RandomNumberGenerator.new()

var _mat_on: StandardMaterial3D
var _mat_off: StandardMaterial3D


func _ready() -> void:
	_rng.randomize()

	# Create white "flash" material
	_mat_on = StandardMaterial3D.new()
	_mat_on.albedo_color = Color(1, 1, 1)
	_mat_on.emission_enabled = true
	_mat_on.emission = Color(1, 1, 1)
	_mat_on.emission_energy = 2.0

	# Create black "off" material
	_mat_off = StandardMaterial3D.new()
	_mat_off.albedo_color = Color(0, 0, 0)
	_mat_off.emission_enabled = false

	# Find meshes and lights under this pane
	for child in get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
		elif child is Light3D:
			_lights.append(child)

	# Start black and with lights off
	_set_on(false)

	# Register this instance
	_instances.append(self)

	# Choose a master controller (drives all panes)
	if _master == null:
		_master = self
		_master_loop()


func _exit_tree() -> void:
	_instances.erase(self)
	if _master == self:
		_master = null
		if _instances.size() > 0:
			_instances[0]._master_loop()


func _set_on(on: bool) -> void:
	# Swap window material
	var chosen := _mat_on if on else _mat_off
	for m in _meshes:
		m.material_override = chosen

	# Toggle any lights on this pane
	for l in _lights:
		l.visible = on


func _compute_next_delay() -> float:
	var delay := base_interval + _rng.randf_range(-interval_jitter, interval_jitter)
	return max(1.0, delay)


func _master_loop() -> void:
	await get_tree().process_frame
	while _master == self:
		await get_tree().create_timer(_compute_next_delay()).timeout
		await _broadcast_lightning()


func _broadcast_lightning() -> void:
	# Big flash
	await _flash_all(0.10)

	# Short pause
	await get_tree().create_timer(0.06).timeout
	if _rng.randi_range(0, 1) == 1:
		await _flash_all(0.08)

	# Occasional tiny after-flash
	if _rng.randf() < 0.4:
		await get_tree().create_timer(0.04).timeout
		await _flash_all(0.05)


func _flash_all(duration: float) -> void:
	# Turn ALL panes/lights on
	for inst in _instances:
		if is_instance_valid(inst):
			inst._set_on(true)

	await get_tree().create_timer(duration).timeout

	# Turn ALL panes/lights off (black)
	for inst in _instances:
		if is_instance_valid(inst):
			inst._set_on(false)
