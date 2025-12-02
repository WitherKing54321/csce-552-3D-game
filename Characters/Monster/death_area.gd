extends Area3D

@export var player_group: String = "player"   # must match your player's group

const GAME_OVER_SCENE := preload("res://UI/GameOverMenu.tscn")

var _active: bool = false
var _triggered: bool = false


func _ready() -> void:
	monitoring = false
	monitorable = true
	body_entered.connect(_on_body_entered)
	print("DeathArea READY on ", get_path(), " (monitoring OFF)")


func set_active(value: bool) -> void:
	_active = value
	monitoring = value
	if not value:
		_triggered = false
	print("DeathArea set_active on ", get_path(), " -> ", _active)


func _on_body_entered(body: Node3D) -> void:
	print("DeathArea body_entered on ", get_path(), " by ", body.name, " | active=", _active)

	if not _active:
		print("  -> not active, ignoring")
		return

	if _triggered:
		print("  -> already triggered once, ignoring")
		return

	if not body.is_in_group(player_group):
		print("  -> body NOT in group '", player_group, "', ignoring")
		return

	_triggered = true
	print("DeathArea: PLAYER HIT, loading GameOverMenu.tscn")
	get_tree().change_scene_to_packed(GAME_OVER_SCENE)
