extends Node3D

# Dialog when the player talks to the guide while standing still
const TALK_DIALOG_LINES: Array[String] = [
	"You're awake. Good. We don't have much time.",
	"I'll lead you out of here. Stay close and do exactly as I say.",
	"When I start moving, don't stop for anything."
]

# Dialog that should play automatically while the guide is walking along the path
const WALK_DIALOG_LINES: Array[String] = [
	"These corridors used to be full of guards. Now it's just us... and it.",
	"Keep your eyes forward. If you hear chains, run faster.",
	"The exit is ahead. If we get separated, follow the torches."
]

@export var player_group := "player"
@export var prompt_text := "Press ENTER to talk"

@onready var area: Area3D = $DialogArea        # make sure the node is really named DialogArea
@onready var prompt: Label3D = $Label3D        # or $DialogArea/Label3D if that's where it lives

var _player_in_range: Node3D = null
var _has_talk_dialog_played: bool = false
var _has_walk_dialog_played: bool = false


func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_in_range = body
		if not _has_talk_dialog_played:
			prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false


func _process(delta: float) -> void:
	if _player_in_range == null:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	# Don't start new dialog if one is already active
	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	# Player-initiated TALK dialog
	if not _has_talk_dialog_played and Input.is_action_just_pressed("dialog_next"):
		if dialog_ui.has_method("start_dialog"):
			dialog_ui.start_dialog(TALK_DIALOG_LINES)
		_has_talk_dialog_played = true
		prompt.visible = false


# --- AUTO WALKING DIALOG (CALLED FROM GUIDE CONTROLLER) ---
func play_walk_dialog() -> void:
	if _has_walk_dialog_played:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("GuideNPC: No node in group 'dialog_ui' found for walk dialog.")
		return

	if dialog_ui.has_method("start_dialog"):
		dialog_ui.start_dialog(WALK_DIALOG_LINES)
		_has_walk_dialog_played = true
	else:
		push_warning("GuideNPC: dialog_ui is missing start_dialog() for walk dialog.")
