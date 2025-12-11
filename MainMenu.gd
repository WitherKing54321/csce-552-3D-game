extends CanvasLayer

@export var game_scene: PackedScene      # drag your MAIN / intro scene here
@export var controls_scene: PackedScene  # drag your ControlsMenu.tscn here
@export var about_scene: PackedScene     # drag your AboutMenu.tscn here   # NEW

# ===== SCROLL AUDIO (preload in code) =====
const SCROLL_SOUND: AudioStream = preload("res://Sounds/MenuScroll.wav")  # change path

var _scroll_player: AudioStreamPlayer = null
var _initial_focus_consumed: bool = false


func _ready() -> void:
	# Make mouse visible for menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Create audio player in code
	_scroll_player = AudioStreamPlayer.new()
	add_child(_scroll_player)

	# Connect buttons
	$Control/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$Control/VBoxContainer/ControlsButton.pressed.connect(_on_controls_pressed)

	# NEW: About button
	if $Control/VBoxContainer.has_node("AboutButton"):
		$Control/VBoxContainer/AboutButton.pressed.connect(_on_about_pressed)

	if $Control/VBoxContainer.has_node("OptionsButton"):
		$Control/VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)

	$Control/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

	# Connect focus signals for scroll sound
	var buttons: Array = []
	buttons.append($Control/VBoxContainer/PlayButton)
	buttons.append($Control/VBoxContainer/ControlsButton)

	if $Control/VBoxContainer.has_node("AboutButton"):
		buttons.append($Control/VBoxContainer/AboutButton)

	if $Control/VBoxContainer.has_node("OptionsButton"):
		buttons.append($Control/VBoxContainer/OptionsButton)

	buttons.append($Control/VBoxContainer/QuitButton)

	for b in buttons:
		b.focus_entered.connect(_on_button_focus_entered)


func _on_button_focus_entered() -> void:
	# Do not play sound for the very first highlight when menu opens
	if not _initial_focus_consumed:
		_initial_focus_consumed = true
		return
	_play_scroll_sound()


func _play_scroll_sound() -> void:
	if _scroll_player and SCROLL_SOUND:
		_scroll_player.stream = SCROLL_SOUND
		_scroll_player.play()


func _on_play_pressed() -> void:
	# starting a new game should reset checkpoints
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
