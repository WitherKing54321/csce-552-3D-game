extends CanvasLayer

@onready var dimmer: ColorRect        = $PauseMenu/ColorRect
@onready var ui_root: VBoxContainer   = $PauseMenu/VBoxContainer
@onready var resume_button: Button    = $PauseMenu/VBoxContainer/Resume
@onready var main_menu_button: Button = $PauseMenu/VBoxContainer/"Main Menu"
@onready var quit_button: Button      = $PauseMenu/VBoxContainer/Quit

# =========================================
# MENU NAV SOUND
# =========================================
var NAV_SOUND: AudioStream = preload("res://Sounds/MenuScroll.wav")
var _nav_player: AudioStreamPlayer
var _suppress_next_nav_sound: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if dimmer:
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	if ui_root:
		ui_root.mouse_filter = Control.MOUSE_FILTER_STOP

	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Create nav sound player
	_nav_player = AudioStreamPlayer.new()
	_nav_player.stream = NAV_SOUND
	_nav_player.autoplay = false
	_nav_player.volume_db = -6.0
	add_child(_nav_player)

	# Play sound when moving between options (via keyboard / controller)
	resume_button.focus_entered.connect(_on_option_focus_entered)
	main_menu_button.focus_entered.connect(_on_option_focus_entered)
	quit_button.focus_entered.connect(_on_option_focus_entered)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	get_tree().paused = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# When menu opens and first button gets focus, do NOT play sound once
	_suppress_next_nav_sound = true
	resume_button.grab_focus()


func _close() -> void:
	visible = false
	get_tree().paused = false
	# Defer so it happens *after* unpausing, avoids weirdness
	call_deferred("_recapture_mouse")

func _recapture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_resume_pressed() -> void:
	_close()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Main.tscn") # adjust path


func _on_quit_pressed() -> void:
	get_tree().quit()


# =========================================
# NAV SOUND HELPER
# =========================================
func _on_option_focus_entered() -> void:
	# Skip the very first focus when menu opens
	if _suppress_next_nav_sound:
		_suppress_next_nav_sound = false
		return

	if _nav_player:
		_nav_player.stop()
		_nav_player.play()
