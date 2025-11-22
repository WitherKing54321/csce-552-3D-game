extends Node3D

@export var player_group := "player"
@export var prompt_text := "Press ENTER to talk"
@export var dialog_lines: Array[String] = [
	"Welcome, traveler.",
	"These halls are dangerous. Stay alert.",
	"If you hear the Warden… run."
]

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Label3D

var _player_in_range: Node3D = null

func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_in_range = body
		prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false

func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	# Do not start if dialog is already running
	if dialog_ui.is_active():
		return

	# ENTER key (your dialog_next action) starts the dialog
	if Input.is_action_just_pressed("dialog_next"):
		dialog_ui.start_dialog(dialog_lines)
		prompt.visible = false
