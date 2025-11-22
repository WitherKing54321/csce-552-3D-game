extends Area3D

@export var dialog_lines: Array[String] = [
	"Welcome, traveler.",
	"I don't have a shop yet, but I can still talk.",
	"Come back when this place isn't collapsing."
]

var _player_in_range: bool = false

@onready var prompt_label: Label3D = $"../Label3D"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = "Press SPACE to talk"

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	# Don't restart if dialog already open
	if dialog_ui.is_active():
		return

	if Input.is_action_just_pressed("ui_accept"):
		dialog_ui.start_dialog(dialog_lines)
		if prompt_label:
			prompt_label.visible = false
