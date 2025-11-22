extends CanvasLayer

@onready var retry_button: Button = $Panel/CenterContainer/VBoxContainer/Retry
@onready var quit_button: Button  = $Panel/CenterContainer/VBoxContainer/Quit

func _ready() -> void:
	# Make sure game is NOT paused, so UI can get input
	get_tree().paused = false

	# Force mouse visible + free
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Continuously check mouse state
	set_process(true)

	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(_delta: float) -> void:
	# If *anything* is trying to recapture/hide the mouse, override it
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_retry_pressed() -> void:
	# When going back to the 3D game, re-capture the mouse for FPS controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
