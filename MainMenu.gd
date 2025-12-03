extends CanvasLayer

@export var game_scene: PackedScene  # Drag your main game scene here

func _ready() -> void:
	# Make mouse visible for menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Connect buttons
	$Control/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	if $Control/VBoxContainer.has_node("OptionsButton"):
		$Control/VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)
	$Control/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)


func _on_options_pressed() -> void:
	print("Options menu placeholder")


func _on_quit_pressed() -> void:
	get_tree().quit()
