# Checkpoint.gd
extends Area3D

@export var one_time: bool = true  # If true, it only triggers once

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	# Save this checkpoint's location
	CheckpointManager.set_checkpoint(global_transform)
	print("Checkpoint set at: ", global_transform.origin)

	# Optional feedback (sound, glow, etc.)
	var sfx := get_node_or_null("AudioStreamPlayer3D")
	if sfx:
		sfx.play()

	if one_time:
		# prevent retrigger spam
		body_entered.disconnect(_on_body_entered)
