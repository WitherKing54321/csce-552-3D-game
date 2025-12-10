extends Node3D

const DIALOG_LINES: Array[String] = [
	"*YELP*",
	"I didn't see you there...",
	"How did you make it here?!",
	"I am not leaving this spot!",
	"We are all going to die..."
]

@export var player_group := "player"
@export var prompt_text := "Press ENTER to talk"

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Label3D

var _player_in_range: Node3D = null
var _has_talked: bool = false


func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_in_range = body
		prompt.visible = not _has_talked


func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false

		var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
		if dialog_ui and dialog_ui.has_method("is_active") and dialog_ui.is_active():
			if dialog_ui.has_method("force_close"):
				dialog_ui.force_close()
			elif dialog_ui is CanvasItem:
				dialog_ui.hide()


func _process(_delta: float) -> void:
	if _player_in_range == null:
		return

	if _has_talked:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	if Input.is_action_just_pressed("dialog_next"):
		if dialog_ui.has_method("start_dialog"):
			dialog_ui.start_dialog(DIALOG_LINES)
		_has_talked = true
		prompt.visible = false
