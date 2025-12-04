extends CanvasLayer

# Change these if your paths are different
@export var main_scene_path: String = "res://Main.tscn"
@export var main_menu_scene_path: String = "res://main_menu.tscn"

@onready var retry_button: Button = (
	get_node_or_null("Panel/CenterContainer/VBoxContainer/Retry") as Button
)

@onready var main_menu_button: Button = (
	get_node_or_null("Panel/CenterContainer/VBoxContainer/MainMenu") as Button
)

@onready var quit_button: Button = (
	get_node_or_null("Panel/CenterContainer/VBoxContainer/Quit") as Button
)


func _ready() -> void:
	# Pause world when success menu is shown
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Connect buttons safely
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	else:
		push_error("SuccessMenu: Retry button not found at Panel/CenterContainer/VBoxContainer/Retry")

	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	else:
		push_error("SuccessMenu: MainMenu button not found at Panel/CenterContainer/VBoxContainer/MainMenu")

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	else:
		push_error("SuccessMenu: Quit button not found at Panel/CenterContainer/VBoxContainer/Quit")

	# Focus Retry by default for keyboard/controller users
	if retry_button:
		retry_button.grab_focus()


func _on_retry_pressed() -> void:
	print("SuccessMenu: Retry pressed")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var err := get_tree().change_scene_to_file(main_scene_path)
	if err != OK:
		push_error("SuccessMenu: Failed to change scene to '%s'" % main_scene_path)


func _on_main_menu_pressed() -> void:
	print("SuccessMenu: Main Menu pressed")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var err := get_tree().change_scene_to_file(main_menu_scene_path)
	if err != OK:
		push_error("SuccessMenu: Failed to change scene to '%s'" % main_menu_scene_path)


func _on_quit_pressed() -> void:
	print("SuccessMenu: Quit pressed")
	get_tree().quit()
