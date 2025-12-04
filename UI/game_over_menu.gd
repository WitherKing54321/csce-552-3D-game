extends CanvasLayer

# Path to your main gameplay scene (the one with Player + checkpoints)
@export var main_scene_path: String = "res://Main.tscn"

# Drag your buttons into these in the Inspector
@export var retry_button_path: NodePath
@export var quit_button_path: NodePath

@onready var retry_button: Button = null
@onready var quit_button: Button = null


func _ready() -> void:
	# Pause the world when Game Over menu is shown
	get_tree().paused = true

	# Make sure this UI works even while paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Show mouse so we can click buttons
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# -------- Get the Retry button --------
	if retry_button_path != NodePath(""):
		var node := get_node_or_null(retry_button_path)
		if node is Button:
			retry_button = node
		else:
			push_error("GameOverMenu: retry_button_path does not point to a Button.")
	else:
		# backup: search by name anywhere under this CanvasLayer
		retry_button = find_child("RetryButton", true, true) as Button

	# -------- Get the Quit button --------
	if quit_button_path != NodePath(""):
		var node2 := get_node_or_null(quit_button_path)
		if node2 is Button:
			quit_button = node2
		else:
			push_error("GameOverMenu: quit_button_path does not point to a Button.")
	else:
		quit_button = find_child("QuitButton", true, true) as Button

	# -------- Connect signals --------
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	else:
		push_error("GameOverMenu: Retry button not found. Set retry_button_path in the Inspector.")

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	else:
		push_error("GameOverMenu: Quit button not found. Set quit_button_path in the Inspector.")

	# Focus Retry by default for keyboard/controller
	if retry_button:
		retry_button.grab_focus()


func _on_retry_pressed() -> void:
	print("GameOverMenu: Retry pressed")

	# Unpause game
	get_tree().paused = false

	# Re-capture mouse for FPS controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Reload the main scene – Player will then use CheckpointManager.get_checkpoint(...)
	var err := get_tree().change_scene_to_file(main_scene_path)
	if err != OK:
		push_error("GameOverMenu: Failed to change scene to '%s'" % main_scene_path)


func _on_quit_pressed() -> void:
	print("GameOverMenu: Quit pressed")
	get_tree().quit()
