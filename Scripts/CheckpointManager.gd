extends Node

var last_checkpoint: Transform3D
var has_checkpoint: bool = false

func set_checkpoint(t: Transform3D) -> void:
	last_checkpoint = t
	has_checkpoint = true

func get_checkpoint(default_transform: Transform3D) -> Transform3D:
	if has_checkpoint:
		return last_checkpoint
	return default_transform
