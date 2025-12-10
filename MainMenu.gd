extends CanvasLayer

@export var game_scene: PackedScene      # drag your MAIN / intro scene here
@export var controls_scene: PackedScene  # drag your ControlsMenu.tscn here
@export var about_scene: PackedScene     # drag your AboutMenu.tscn here   <--- NEW

func _ready() -> void:
	# Make mouse visible for menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Connect buttons
	$Control/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$Control/VBoxContainer/ControlsButton.pressed.connect(_on_controls_pressed)

	# NEW: About button
	if $Control/VBoxContainer.has_node("AboutButton"):
		$Control/VBoxContainer/AboutButton.pressed.connect(_on_about_pressed)

	if $Control/VBoxContainer.has_node("OptionsButton"):
		$Control/VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)

	$Control/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	# NEW: starting a new game should reset checkpoints
	CheckpointManager.clear_checkpoint()

	if game_scene:
		get_tree().change_scene_to_packed(game_scene)


func _on_controls_pressed() -> void:
	if controls_scene:
		get_tree().change_scene_to_packed(controls_scene)


# NEW
func _on_about_pressed() -> void:
	if about_scene:
		get_tree().change_scene_to_packed(about_scene)


func _on_options_pressed() -> void:
	print("Options menu placeholder")


func _on_quit_pressed() -> void:
	get_tree().quit()
