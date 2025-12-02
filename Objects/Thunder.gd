extends Node3D
class_name FlashPaneRoot

@export var base_interval: float = 8.0
@export var interval_jitter: float = 2.0

# Thunder settings
@export var thunder_stream: AudioStream
@export var thunder_volume_db: float = 0.0
@export var thunder_min_delay: float = 0.3   # seconds after first flash
@export var thunder_max_delay: float = 1.2   # seconds after first flash

static var _master: FlashPaneRoot = null
static var _instances: Array[FlashPaneRoot] = []

var _meshes: Array[MeshInstance3D] = []
var _lights: Array[Light3D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _mat_on: StandardMaterial3D
var _mat_off: StandardMaterial3D

var _thunder_player: AudioStreamPlayer3D = null


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
			_meshes.append(child as MeshInstance3D)
		elif child is Light3D:
			_lights.append(child as Light3D)

	# Start black and with lights off
	_set_on(false)

	# Register this instance
	_instances.append(self)

	# Choose a master controller (drives all panes)
	if _master == null:
		_master = self
		_create_thunder_player()
		_master_loop()


func _exit_tree() -> void:
	_instances.erase(self)

	if _master == self:
		_master = null

		# Clean up thunder player
		if _thunder_player and is_instance_valid(_thunder_player):
			_thunder_player.queue_free()
			_thunder_player = null

		# Hand off master role to another pane if any left
		if _instances.size() > 0:
			_master = _instances[0]
			_master._create_thunder_player()
			_master._master_loop()


func _create_thunder_player() -> void:
	if thunder_stream == null:
		return

	# Already created
	if _thunder_player and is_instance_valid(_thunder_player):
		return

	_thunder_player = AudioStreamPlayer3D.new()
	_thunder_player.stream = thunder_stream
	_thunder_player.autoplay = false
	_thunder_player.volume_db = thunder_volume_db
	add_child(_thunder_player)


func _set_on(on: bool) -> void:
	var chosen: StandardMaterial3D = _mat_on if on else _mat_off

	# Swap window material
	for m in _meshes:
		if is_instance_valid(m):
			m.material_override = chosen

	# Toggle any lights on this pane
	for l in _lights:
		if is_instance_valid(l):
			l.visible = on


func _compute_next_delay() -> float:
	var delay: float = base_interval + _rng.randf_range(-interval_jitter, interval_jitter)
	return max(1.0, delay)


func _master_loop() -> void:
	await get_tree().process_frame
	while _master == self:
		await get_tree().create_timer(_compute_next_delay()).timeout
		await _broadcast_lightning()


func _broadcast_lightning() -> void:
	# First big flash
	await _flash_all(0.10)

	# Kick off thunder with a random delay AFTER the first flash.
	# This runs in parallel; we don't await it here.
	_play_thunder_after_delay()

	# Short pause before possible second flash
	await get_tree().create_timer(0.06).timeout
	if _rng.randi_range(0, 1) == 1:
		await _flash_all(0.08)

	# Occasional tiny after-flash
	if _rng.randf() < 0.4:
		await get_tree().create_timer(0.04).timeout
		await _flash_all(0.05)


func _play_thunder_after_delay() -> void:
	if _thunder_player == null or thunder_stream == null:
		return

	var delay: float = _rng.randf_range(thunder_min_delay, thunder_max_delay)

	# Start a small async coroutine
	_play_thunder_coroutine(delay)


func _play_thunder_coroutine(delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	# If this pane is no longer master, don't play
	if _master != self:
		return

	# Restart thunder if it was already playing
	if _thunder_player.playing:
		_thunder_player.stop()
	_thunder_player.play()


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
