extends Area3D

@export var chase_controller: Node3D          # the ChaseController for THIS chase
@export var player_group: String = "player"   # group your player is in

var _triggered: bool = false


func _ready() -> void:
	print("ChaseTrigger READY on ", get_path())
	print("  chase_controller =", chase_controller)
	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	print("ChaseTrigger body_entered on ", get_path())
	print("  body:", body.name, " triggered:", _triggered)

	if _triggered:
		print("  -> already triggered, ignoring")
		return

	if not body.is_in_group(player_group):
		print("  -> body is NOT in group '", player_group, "', ignoring")
		return

	_triggered = true
	print("  -> PLAYER entered trigger, starting chase")
	print("  chase_controller =", chase_controller)

	if chase_controller and chase_controller.has_method("start_chase"):
		chase_controller.start_chase()
	else:
		push_error("ChaseTrigger ERROR: chase_controller is NOT set or has no start_chase()")
