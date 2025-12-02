extends Node3D

# ================== AUDIO =====================
const CHASE_LOOP: AudioStream = preload("res://Sounds/MonsterWalk.wav")

# ================== EXPORTS ====================
# These are per-chase references you set in the Inspector.
@export var path_follow: PathFollow3D          # e.g. MonsterPathFollow
@export var monster_root: Node3D               # root of the monster model for this chase
@export var death_area: Area3D                 # the Area3D that kills the player
@export var speed: float = 8.0                 # movement speed along the path
@export var auto_reset: bool = false           # if true, loop back to start at end
@export var chase_volume_db: float = 20       # volume of the chase loop

var _active: bool = false
var _chase_player: AudioStreamPlayer3D = null  # runtime audio player


func _ready() -> void:
	print("--- ChaseController _ready on ", name, " ---")
	print("  path_follow =", path_follow)
	print("  monster_root =", monster_root)
	print("  death_area =", death_area)

	# Create audio player for chase loop
	_chase_player = AudioStreamPlayer3D.new()
	_chase_player.stream = CHASE_LOOP
	_chase_player.autoplay = false
	_chase_player.volume_db = chase_volume_db
	add_child(_chase_player)

	# Hide monster at start
	if monster_root:
		monster_root.visible = false
		monster_root.process_mode = Node.PROCESS_MODE_DISABLED
		print("  -> MonsterRoot hidden at start")
	else:
		push_error("ChaseController(" + name + "): monster_root is NOT set in Inspector")

	# Disable death hitbox at start
	if death_area:
		if death_area.has_method("set_active"):
			death_area.set_active(false)
		else:
			death_area.monitoring = false
		print("  -> DeathArea disabled at start")
	else:
		push_error("ChaseController(" + name + "): death_area is NOT set in Inspector")


func start_chase() -> void:
	if path_follow == null:
		push_error("ChaseController(" + name + "): path_follow is NOT set, cannot start chase")
		return

	print("--- ChaseController START CHASE on ", name, " ---")
	_active = true
	path_follow.progress = 0.0

	# Show monster
	if monster_root:
		monster_root.visible = true
		monster_root.process_mode = Node.PROCESS_MODE_INHERIT
		print("  -> MonsterRoot made visible")

	# Enable death hitbox
	if death_area:
		if death_area.has_method("set_active"):
			death_area.set_active(true)
		else:
			death_area.monitoring = true
		print("  -> DeathArea enabled")

	# Start or restart chase audio
	if _chase_player and CHASE_LOOP:
		# keep volume in sync with exported value
		_chase_player.volume_db = chase_volume_db

		if _chase_player.playing:
			_chase_player.stop()
		_chase_player.play()


func stop_chase() -> void:
	# Manual stop helper (optional, but useful)
	_active = false

	if death_area:
		if death_area.has_method("set_active"):
			death_area.set_active(false)
		else:
			death_area.monitoring = false

	if monster_root:
		monster_root.visible = false
		monster_root.process_mode = Node.PROCESS_MODE_DISABLED

	if _chase_player and _chase_player.playing:
		_chase_player.stop()


func _process(delta: float) -> void:
	if not _active or path_follow == null:
		return

	path_follow.progress += speed * delta

	# Optional: stop at end of path
	var path_node = path_follow.get_parent()
	if not (path_node is Path3D):
		return

	var curve = (path_node as Path3D).curve
	if curve == null:
		return

	if path_follow.progress >= curve.get_baked_length():
		print("--- ChaseController reached end of path on ", name, " ---")
		_active = false

		# Turn off lethal hitbox when done
		if death_area:
			if death_area.has_method("set_active"):
				death_area.set_active(false)
			else:
				death_area.monitoring = false

		# Hide monster when done
		if monster_root:
			monster_root.visible = false
			monster_root.process_mode = Node.PROCESS_MODE_DISABLED

		# Stop chase audio when done
		if _chase_player and _chase_player.playing:
			_chase_player.stop()

		if auto_reset:
			path_follow.progress = 0.0
