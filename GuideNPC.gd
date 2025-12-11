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
	"He wants to rule this castle and kill us all."
]

# 3) Dialog when the player reaches the bottom of the staircase
const END_DIALOG_LINES: Array[String] = [
	"I won't go any further.",
	"I have a bad feeling in my gut..."
]

# AUDIO: one set per dialog type
const TALK_DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/GuideNPC Line 1.wav"),
	preload("res://Sounds/GuideNPC Line 2.wav")
]

const WALK_DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/GuideNPC Line 3.wav"),
	preload("res://Sounds/GuideNPC Line 4.wav"),
	preload("res://Sounds/GuideNPC Line 5.wav"),
	preload("res://Sounds/GuideNPC Line 6.wav")
]

const END_DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/GuideNPC Line 7.wav"),
	preload("res://Sounds/GuideNPC Line 8.wav")
]

@export var player_group := "player"

# Trigger near the guard for the first dialog
@export var talk_trigger: Area3D
# Trigger at bottom of the staircase for the third dialog
@export var stair_trigger: Area3D

var _has_talk_dialog_played: bool = false
var _has_walk_dialog_played: bool = false
var _has_end_dialog_played: bool = false

@onready var anim: AnimationPlayer = $"GuideController/Path3D/PathFollow3D/GuardRoot/GAUrdleader/AnimationPlayer" as AnimationPlayer

# Node that moves with the guard so audio follows correctly
@onready var _voice_anchor: Node3D = $"GuideController/Path3D/PathFollow3D/GuardRoot" as Node3D

enum DialogType { NONE, TALK, WALK, END }
var _current_dialog_type: int = DialogType.NONE

var _audio_player: AudioStreamPlayer3D = null


func _ready() -> void:
	anim.play("idle")

	# Create 3D audio player and parent it to the moving guard root
	_audio_player = AudioStreamPlayer3D.new()
	if _voice_anchor:
		_voice_anchor.add_child(_audio_player)
		_audio_player.transform = Transform3D.IDENTITY
	else:
		push_warning("GuideNPC: _voice_anchor not found, audio will not follow the guard.")
		add_child(_audio_player)

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


# ---------- FIRST DIALOG: near the guard (trigger) ----------

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

	# Wait for any current dialog to finish
	if dialog_ui.has_method("is_active"):
		while dialog_ui.is_active():
			await get_tree().create_timer(0.1).timeout

	if dialog_ui.has_method("start_dialog"):
		_current_dialog_type = DialogType.TALK
		dialog_ui.start_dialog(TALK_DIALOG_LINES, self)
		_has_talk_dialog_played = true
	else:
		push_warning("GuideNPC: dialog_ui is missing start_dialog() for TALK dialog.")


# ---------- SECOND DIALOG: while walking (called from GuideController) ----------

func play_walk_dialog() -> void:
	if _has_walk_dialog_played:
		return

	anim.play("walk")

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("GuideNPC: No node in group 'dialog_ui' found for WALK dialog.")
		return

	# Do not interrupt any active dialog
	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	if dialog_ui.has_method("start_dialog"):
		_current_dialog_type = DialogType.WALK
		dialog_ui.start_dialog(WALK_DIALOG_LINES, self)
		_has_walk_dialog_played = true
	else:
		push_warning("GuideNPC: dialog_ui is missing start_dialog() for WALK dialog.")


# ---------- THIRD DIALOG: bottom of staircase (trigger) ----------

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

	# Wait for any current dialog (like the walk dialog) to finish
	if dialog_ui.has_method("is_active"):
		while dialog_ui.is_active():
			await get_tree().create_timer(0.1).timeout

	if dialog_ui.has_method("start_dialog"):
		_current_dialog_type = DialogType.END
		dialog_ui.start_dialog(END_DIALOG_LINES, self)
		_has_end_dialog_played = true
	else:
		push_warning("GuideNPC: dialog_ui is missing start_dialog() for END dialog.")


# ---------- AUDIO API FOR dialog_ui ----------

func play_line_audio(line_index: int) -> void:
	if _audio_player == null:
		return

	var audio_array: Array[AudioStream] = []

	match _current_dialog_type:
		DialogType.TALK:
			audio_array = TALK_DIALOG_AUDIO
		DialogType.WALK:
			audio_array = WALK_DIALOG_AUDIO
		DialogType.END:
			audio_array = END_DIALOG_AUDIO
		_:
			return

	if line_index < 0 or line_index >= audio_array.size():
		return

	if _audio_player.playing:
		_audio_player.stop()

	_audio_player.stream = audio_array[line_index]
	_audio_player.play()


func stop_line_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
