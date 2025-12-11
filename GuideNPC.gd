extends Node3D

# 1) First dialog when the player reaches the NPC
const TALK_DIALOG_LINES: Array[String] = [
	"People are dying here left and right.",
	"Staying here is a death wish, let's go."
]

# 2) Auto-play dialog while the guide is walking
const WALK_DIALOG_LINES: Array[String] = [
	"I've heard stories about this monster...",
	"At first, the wizard created it to protect us.",
	"But now, he wishes to use it for evil.",
	"He wants to rule this castle...",
	"And kill us all..."
]

# 3) Dialog when the player reaches the bottom of the staircase
const END_DIALOG_LINES: Array[String] = [
	"I won't go any further.",
	"I have a bad feeling in my gut..."
]

@export var player_group := "player"

# Trigger near the guard for the FIRST dialog
@export var talk_trigger: Area3D
# Trigger at bottom of the staircase for the THIRD dialog
@export var stair_trigger: Area3D

var _has_talk_dialog_played: bool = false
var _has_walk_dialog_played: bool = false
var _has_end_dialog_played: bool = false
@onready var anim: AnimationPlayer = $"GuideController/Path3D/PathFollow3D/GuardRoot/GAUrdleader/AnimationPlayer" as AnimationPlayer

func _ready() -> void:
	anim.play("idle")
	# Connect trigger for first dialog
	if talk_trigger:
		talk_trigger.body_entered.connect(_on_talk_trigger_body_entered)
	else:
		push_warning("GuideNPC: 'talk_trigger' is not assigned in the Inspector.")

	# Connect trigger for third dialog
	if stair_trigger:
		stair_trigger.body_entered.connect(_on_stair_trigger_body_entered)
	else:
		push_warning("GuideNPC: 'stair_trigger' is not assigned in the Inspector.")


# ------- FIRST DIALOG: near the guard (trigger) -------

func _on_talk_trigger_body_entered(body: Node) -> void:
	if _has_talk_dialog_played:
		return
	if not body.is_in_group(player_group):
		return

	play_talk_dialog()


func play_talk_dialog() -> void:
	if _has_talk_dialog_played:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("GuideNPC: No node in group 'dialog_ui' found for TALK dialog.")
		return

	# If your dialog UI has is_active(), wait for any current dialog to finish
	if dialog_ui.has_method("is_active"):
		while dialog_ui.is_active():
			await get_tree().create_timer(0.1).timeout

	if dialog_ui.has_method("start_dialog"):
		dialog_ui.start_dialog(TALK_DIALOG_LINES)
		_has_talk_dialog_played = true
	else:
		push_warning("GuideNPC: dialog_ui is missing start_dialog() for TALK dialog.")
		

# ------- SECOND DIALOG: while walking (called from GuideController) -------

func play_walk_dialog() -> void:
	if _has_walk_dialog_played:
		return
	anim.play("walk")
	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("GuideNPC: No node in group 'dialog_ui' found for WALK dialog.")
		return

	# Don't interrupt any active dialog
	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	if dialog_ui.has_method("start_dialog"):
		dialog_ui.start_dialog(WALK_DIALOG_LINES)
		_has_walk_dialog_played = true
	else:
		push_warning("GuideNPC: dialog_ui is missing start_dialog() for WALK dialog.")


# ------- THIRD DIALOG: bottom of staircase (trigger) -------

func _on_stair_trigger_body_entered(body: Node) -> void:
	anim.play("idle")
	if _has_end_dialog_played:
		return
	if not body.is_in_group(player_group):
		return

	play_end_dialog()


func play_end_dialog() -> void:
	if _has_end_dialog_played:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("GuideNPC: No node in group 'dialog_ui' found for END dialog.")
		return

	# Wait for any current dialog (like the WALK dialog) to finish
	if dialog_ui.has_method("is_active"):
		while dialog_ui.is_active():
			await get_tree().create_timer(0.1).timeout

	if dialog_ui.has_method("start_dialog"):
		dialog_ui.start_dialog(END_DIALOG_LINES)
		_has_end_dialog_played = true
	else:
		push_warning("GuideNPC: dialog_ui is missing start_dialog() for END dialog.")
