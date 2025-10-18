extends Node3D
class_name SwordItem

@export var sword_name: String = "First Sword"
@export var bonus_damage: int = 2
@export var grip_position     : Vector3 = Vector3.ZERO
@export var grip_rotation_deg : Vector3 = Vector3.ZERO
@export var grip_scale        : Vector3 = Vector3.ONE

func on_equipped(holder: Node) -> void:
	print(sword_name, "equipped by", holder.name)

func on_unequipped(holder: Node) -> void:
	print(sword_name, "unequipped by", holder.name)
