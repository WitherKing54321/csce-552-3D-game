extends Area3D

@export var guide_controller: Node3D   # set per-trigger in Inspector

var _triggered := false


func _ready() -> void:
	print("GuideTrigger READY on node:", get_path())
	print("  guide_controller set to:", guide_controller)

	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return

	print("GuideTrigger body_entered:", body)

	if not body.is_in_group("player"):
		print("  -> body is NOT in group 'player', ignoring")
		return

	_triggered = true
	print("  -> PLAYER entered guide trigger, starting guide walk")
	print("  guide_controller =", guide_controller)

	if guide_controller and guide_controller.has_method("start_walk"):
		guide_controller.start_walk()
	else:
		push_error("GuideTrigger ERROR: guide_controller is NOT set or has no start_walk()")
