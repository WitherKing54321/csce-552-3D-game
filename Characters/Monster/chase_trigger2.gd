extends Area3D

@export var chase_controller: Node3D   # Drag your ChaseController here in the editor

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return

	if body.is_in_group("player"):
		_triggered = true
		if chase_controller != null and chase_controller.has_method("start_chase"):
			chase_controller.start_chase()
