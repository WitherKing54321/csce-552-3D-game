extends Node

var has_checkpoint: bool = false
var last_checkpoint_transform: Transform3D


func set_checkpoint(t: Transform3D) -> void:
	last_checkpoint_transform = t
	has_checkpoint = true
	print("CheckpointManager: checkpoint set at ", t.origin)


# This matches what your player.gd is calling:
func get_checkpoint(default_transform: Transform3D) -> Transform3D:
	if has_checkpoint:
		return last_checkpoint_transform
	return default_transform


# Optional alias if you ever used the older name:
func get_spawn_transform(default_transform: Transform3D) -> Transform3D:
	return get_checkpoint(default_transform)


func clear_checkpoint() -> void:
	has_checkpoint = false
