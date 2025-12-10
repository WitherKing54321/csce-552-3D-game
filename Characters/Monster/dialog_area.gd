extends Area3D

@export var dialog_lines: Array[String] = [
	"Welcome, traveler.",
	"I don't have a shop yet, but I can still talk.",
	"Come back when this place isn't collapsing."
]
@export var one_time_only: bool = true

var _player_in_range: bool = false
var _dialog_done: bool = false   # should flip to true after full dialog

@onready var prompt_label: Label3D = $"../Label3D"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = "Press E to talk"

	# IMPORTANT: defer connecting so dialog_ui has time to join the group
	call_deferred("_connect_dialog_ui")


func _connect_dialog_ui() -> void:
	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui and dialog_ui.has_signal("dialog_finished"):
		if not dialog_ui.dialog_finished.is_connected(_on_dialog_finished):
			dialog_ui.dialog_finished.connect(_on_dialog_finished)
			#print("DialogArea: Connected to dialog_finished")  # optional debug


func _on_dialog_finished() -> void:
	# Called ONLY when the dialog fully completes its last line
	_dialog_done = true
	#print("DialogArea: dialog finished, marking done")  # optional debug

	if one_time_only and prompt_label:
		prompt_label.visible = false


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = true

	# If dialog is one-time-only and already done, never show prompt again
	if one_time_only and _dialog_done:
		return

	if prompt_label:
		prompt_label.visible = true


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = false

	if prompt_label:
		prompt_label.visible = false

	# Reset so dialog can be replayed on next entry
	_dialog_done = false

	# Hide/close the dialog UI if active
	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui and dialog_ui.has_method("force_close"):
		dialog_ui.force_close()



func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	# If one-time and already done, NEVER allow dialog again
	if one_time_only and _dialog_done:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	# Don't restart if dialog already open
	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	# Start dialog when player presses ENTER (or your chosen key)
	if Input.is_action_just_pressed("dialog_next"):  # or "ui_accept" if you prefer
		if dialog_ui.has_method("start_dialog"):
			dialog_ui.start_dialog(dialog_lines)
			if prompt_label:
				prompt_label.visible = false
