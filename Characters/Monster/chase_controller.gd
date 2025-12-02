extends Node3D

# These are per-chase references you set in the Inspector.
@export var path_follow: PathFollow3D          # e.g. MonsterPathFollow
@export var monster_root: Node3D               # root of the monster model for this chase
@export var death_area: Area3D                 # the Area3D that kills the player
@export var speed: float = 8.0                 # movement speed along the path
@export var auto_reset: bool = false           # if true, loop back to start at end

var _active: bool = false


func _ready() -> void:
	print("--- ChaseController _ready on ", name, " ---")
	print("  path_follow =", path_follow)
	print("  monster_root =", monster_root)
	print("  death_area =", death_area)

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

		if auto_reset:
			path_follow.progress = 0.0
