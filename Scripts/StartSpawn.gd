# StartSpawn.gd
extends Node3D

func _ready() -> void:
	# First checkpoint is the start of the game
	CheckpointManager.set_checkpoint(global_transform)
