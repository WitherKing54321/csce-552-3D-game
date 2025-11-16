extends Area3D

var _has_killed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _has_killed:
		return

	if body.is_in_group("player"):
		_has_killed = true

		# 1) Optionally: disable player input
		if body.has_method("disable_input"):
			body.disable_input()

		# 2) Trigger jumpscare (replace with your own logic)
		_play_jumpscare(body)

		# 3) Game Over (replace with your own scene/handler)
		_game_over()

func _play_jumpscare(player: Node) -> void:
	# Example placeholder:
	# - Show a UI scene with a big monster face
	# - Or play an animation on the monster model
	# You can wire this to your own AnimationPlayer or UI manager
	pass

func _game_over() -> void:
	# Simplest version: change to a Game Over scene
	# get_tree().change_scene_to_file("res://UI/GameOver.tscn")
	#
	# Or call a global manager:
	# GameManager.game_over()
	pass
