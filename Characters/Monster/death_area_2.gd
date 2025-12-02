extends Area3D

const GAME_OVER_SCENE := preload("res://UI/GameOverMenu.tscn")

var active: bool = false

func _ready() -> void:
	monitoring = false
	monitorable = true
	body_entered.connect(_on_body_entered)
	print("DeathArea: ready (monitoring OFF)")

func set_active(value: bool) -> void:
	active = value
	monitoring = value
	print("DeathArea: set_active -> ", active)

func _on_body_entered(body: Node3D) -> void:
	print("DeathArea: body entered -> ", body.name, " | active=", active)

	if not active:
		return

	# Only kill the player – assumes your player is in "player" group
	if not body.is_in_group("player"):
		print("  -> Not the player, ignoring")
		return

	print("DeathArea: PLAYER HIT, loading GameOverMenu")
	get_tree().change_scene_to_packed(GAME_OVER_SCENE)
