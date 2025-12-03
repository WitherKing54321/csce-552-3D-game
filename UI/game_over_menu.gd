extends CanvasLayer

@export var retry_button_path: NodePath
@export var quit_button_path: NodePath

@onready var retry_button: Button = get_node_or_null(retry_button_path) as Button
@onready var quit_button: Button  = get_node_or_null(quit_button_path) as Button


func _ready() -> void:
	# Make sure the game is NOT paused when we arrive here
	get_tree().paused = false

	# This UI should always process input, no matter what
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = true

	# Mouse visible + free for menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	set_process(true)

	# Hook up buttons (with safety checks)
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	else:
		push_error("GameOverMenu: retry_button_path is not set or not a Button")

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	else:
		push_error("GameOverMenu: quit_button_path is not set or not a Button")

	# Focus the Retry button for keyboard/pad users
	if retry_button:
		retry_button.grab_focus()


func _process(_delta: float) -> void:
	# Keep mouse visible while this menu is open
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_retry_pressed() -> void:
	print("GameOverMenu: Retry pressed")
	_go_to_main_menu()


func _on_quit_pressed() -> void:
	print("GameOverMenu: Quit pressed")
	get_tree().quit()


# =========================================
# SHARED: GO TO MAIN MENU
# =========================================
func _go_to_main_menu() -> void:
	# Just in case something paused the tree, unpause now
	get_tree().paused = false

	# Show mouse for main menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	get_tree().change_scene_to_file("res://MainMenu.tscn")
