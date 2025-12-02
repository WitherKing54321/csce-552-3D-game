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

	# Connect buttons if not already connected in the editor
	if retry_button and not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)

	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _process(_delta: float) -> void:
	# Keep mouse visible while this menu is open
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_retry_pressed() -> void:
	print("GameOverMenu: Retry pressed")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Reloading Main.tscn will cause the player to spawn at the last checkpoint
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_quit_pressed() -> void:
	print("GameOverMenu: Quit pressed")
	get_tree().quit()
