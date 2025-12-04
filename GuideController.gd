extends Node3D

@export var path_follow: PathFollow3D          # Path3D/PathFollow3D
@export var guide_root: Node3D                 # the visible guide model root
@export var speed: float = 3.0
@export var auto_reset: bool = false           # loop back to start at end?

# Drag your GuideNPC node into this in the Inspector (optional;
# if you leave it empty, script will try to find a child named "GuideNPC")
@export var guide_npc_path: NodePath

var guide_npc: Node = null
var _active: bool = false


func _ready() -> void:
	# Auto-find PathFollow3D if not assigned
	if path_follow == null:
		var candidate = get_node_or_null("Path3D/PathFollow3D")
		if candidate is PathFollow3D:
			path_follow = candidate

	# Auto-find the visual root if not assigned
	if guide_root == null:
		for child in get_children():
			if child is Node3D and not (child is Path3D or child is PathFollow3D):
				guide_root = child
				break

	# Get the GuideNPC reference
	if guide_npc_path != NodePath(""):
		guide_npc = get_node_or_null(guide_npc_path)
	else:
		guide_npc = get_node_or_null("GuideNPC")

	# Warnings if something is missing
	if path_follow == null:
		push_warning("GuideController: path_follow is not set and could not be auto-found.")
	if guide_root == null:
		push_warning("GuideController: guide_root is not set and could not be auto-found.")
	if guide_npc == null:
		push_warning("GuideController: guide_npc not set/found. Walk dialog will NOT play.")


func _process(delta: float) -> void:
	if not _active:
		return
	if path_follow == null or guide_root == null:
		return

	# Move along the path
	path_follow.progress += speed * delta

	# Handle end of path
	if path_follow.progress_ratio >= 1.0:
		if auto_reset:
			path_follow.progress = 0.0
		else:
			_active = false

	# Keep guide upright: copy only the position from the path
	var path_transform: Transform3D = path_follow.global_transform
	var guide_transform: Transform3D = guide_root.global_transform
	guide_transform.origin = path_transform.origin
	guide_root.global_transform = guide_transform


func start_walk() -> void:
	if path_follow == null:
		push_error("GuideController ERROR: path_follow is not set.")
		return

	_active = true
	print("GuideController: start_walk() called, guide ACTIVE.")

	# Trigger automatic walking dialog
	if guide_npc != null and guide_npc.has_method("play_walk_dialog"):
		guide_npc.play_walk_dialog()
	else:
		push_warning("GuideController: guide_npc is null or missing play_walk_dialog().")


func stop_walk() -> void:
	_active = false
	print("GuideController: stop_walk() called, guide INACTIVE.")
