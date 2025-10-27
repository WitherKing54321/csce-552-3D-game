# res://pause_menu.gd (on the PauseMenu2 CanvasLayer)
extends CanvasLayer

@onready var ui_root: Control = $VBoxContainer
@onready var dimmer: ColorRect = $ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # still receives Esc when paused
	visible = false                           # start hidden
	# Block clicks from leaking to the game when open
	if dimmer: dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	if ui_root: ui_root.mouse_filter = Control.MOUSE_FILTER_STOP

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		toggle()

func toggle() -> void:
	if visible: _close()
	else: _open()

func _open() -> void:
	get_tree().paused = true
	visible = true
	# If your game captures the mouse, show it while paused:
	# Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close() -> void:
	visible = false
	get_tree().paused = false
	# Re-capture here if needed:
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
