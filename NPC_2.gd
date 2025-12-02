extends Node3D

@export var player_group := "player"
@export var prompt_text := "Press ENTER to talk"
@export var dialog_lines: Array[String] = [
	"How did you survive that thing?!",
	"I'm never leaving this spot...",
	"We are all going to die..."
]
@export var one_time_only: bool = true   # allow turning replay on/off in Inspector

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Label3D

var _player_in_range: Node3D = null
var _dialog_played: bool = false         # tracks if dialog has already run once

func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		# If this is one-time-only and already played, do nothing
		if one_time_only and _dialog_played:
			return
		_player_in_range = body
		prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false

		# Also hide/stop the dialog UI if it’s currently active
		var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
		if dialog_ui and dialog_ui.has_method("is_active") and dialog_ui.is_active():
			if dialog_ui.has_method("force_close"):
				dialog_ui.force_close()      # if you added a custom close method
			elif dialog_ui is CanvasItem:
				dialog_ui.hide()            # at least hide the control


func _process(_delta: float) -> void:
	# No player nearby? do nothing
	if _player_in_range == null:
		return

	# Prevent replay if one-time-only
	if one_time_only and _dialog_played:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	# Do not start if dialog is already running (if method exists)
	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	# ENTER key (your dialog_next action) starts the dialog
	if Input.is_action_just_pressed("dialog_next"):
		if dialog_ui.has_method("start_dialog"):
			dialog_ui.start_dialog(dialog_lines)
		_dialog_played = true      # mark as done so it will not replay
		prompt.visible = false
