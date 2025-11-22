# res://Characters/Monster/death_area.gd  (path can be different, that’s fine)
extends Area3D

@export var player_group: String = "player_global"  # or "player" if that's your group

const GAME_OVER_SCENE := preload("res://UI/GameOverMenu.tscn")

var _triggered: bool = false
var _active: bool = false

func _ready() -> void:
	# Start OFF; chase controller will call enable()
	monitoring = false
	monitorable = true

	body_entered.connect(_on_body_entered)
	print("Death area ready")

# --- called from chase_controller_2.gd ---

func enable() -> void:
	_active = true
	monitoring = true
	print("Death area ENABLED")

func disable() -> void:
	_active = false
	monitoring = false
	print("Death area DISABLED")

# --- collision handler ---

func _on_body_entered(body: Node3D) -> void:
	print("Death area entered by:", body.name)

	# Only work during chase
	if not _active:
		return

	# Don't refire after first player hit
	if _triggered:
		return

	# Only react to the player
	if not body.is_in_group(player_group):
		return

	_triggered = true
	print("Death area: PLAYER hit -> switching to GameOverMenu")

	get_tree().change_scene_to_packed(GAME_OVER_SCENE)
