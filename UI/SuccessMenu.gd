extends CanvasLayer

@onready var retry_button: Button = $Panel/CenterContainer/VBoxContainer/Retry
@onready var quit_button: Button  = $Panel/CenterContainer/VBoxContainer/Quit


func _ready() -> void:
	# Make sure game is NOT paused, so UI can get input
	get_tree().paused = false

	# This UI should always process input
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Force mouse visible + free
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Continuously check mouse state
	set_process(true)

	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Focus the Retry button for keyboard/pad navigation
	retry_button.grab_focus()


func _process(_delta: float) -> void:
	# If *anything* is trying to recapture/hide the mouse, override it
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_retry_pressed() -> void:
	print("SuccessMenu: Retry pressed")
	_go_to_main_menu()


func _on_quit_pressed() -> void:
	print("SuccessMenu: Quit pressed")
	get_tree().quit()


# =========================================
# SHARED: GO TO MAIN MENU
# =========================================
func _go_to_main_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://MainMenu.tscn")
