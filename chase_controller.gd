extends Node3D

@export var path_follow: PathFollow3D        # Drag MonsterPathFollow here
@export var speed: float = 8.0               # Units per second along the path
@export var auto_reset: bool = false         # If true, loop back to start when done

var _active: bool = false


func _ready() -> void:
	# If nothing is assigned in the Inspector, try to find it automatically
	if path_follow == null:
		var candidate := get_node_or_null("MonsterPathFollow")
		if candidate == null:
			candidate = get_node_or_null("MonsterPath/MonsterPathFollow")
		if candidate is PathFollow3D:
			path_follow = candidate


func start_chase() -> void:
	if path_follow == null:
		return

	_active = true
	path_follow.progress = 0.0
	# Start chase SFX/music here if you want


func reset_chase() -> void:
	_active = false


func _process(delta: float) -> void:
	if not _active:
		return
	if path_follow == null:
		return

	# Move along the path
	path_follow.progress += speed * delta

	# Stop at the end of the path (optional)
	var path := path_follow.get_parent() as Path3D
	if path == null:
		return

	var curve: Curve3D = path.curve
	if curve == null:
		return

	if path_follow.progress >= curve.get_baked_length():
		_active = false
		if auto_reset:
			path_follow.progress = 0.0
