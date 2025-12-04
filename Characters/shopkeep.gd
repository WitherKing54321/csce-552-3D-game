extends Node3D

# ================= DIALOG TEXT =================
# Typed dialog array so it matches start_dialog(lines: Array[String])
const DIALOG_LINES: Array[String] = [
	"Where did you come from?",
	"Oh, it doesn't matter, but watch out...",
	"I've heard a lot of screaming today..."
]

# ================= DIALOG AUDIO =================
# Each entry lines up with DIALOG_LINES by index
const DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/ShopKeep Line 1 .wav"),
	preload("res://Sounds/ShopKeep Line 2.wav"),
	preload("res://Sounds/ShopKeep Line 3.wav")
]

@export var player_group := "player"
@export var prompt_text := "Press ENTER to talk"

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Label3D

var _player_in_range: Node3D = null
var _has_talked: bool = false   # one-time only flag
var _audio_player: AudioStreamPlayer3D = null


func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	# Create the audio player in code, no node in the scene needed
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.stream = null
	_audio_player.autoplay = false
	add_child(_audio_player)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_in_range = body
		# Only show prompt if they have never talked before
		prompt.visible = not _has_talked


func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false

		stop_line_audio()

		# (Optional) close dialog UI if it's still open
		var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
		if dialog_ui and dialog_ui.has_method("is_active") and dialog_ui.is_active():
			if dialog_ui.has_method("force_close"):
				dialog_ui.force_close()
			elif dialog_ui is CanvasItem:
				dialog_ui.hide()


func _process(_delta: float) -> void:
	if _player_in_range == null:
		return

	# Already spoke once in this playthrough → never again
	if _has_talked:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	if Input.is_action_just_pressed("dialog_next"):
		# IMPORTANT: we now pass "self" as the speaker
		# so the dialog_ui can call back into us for audio
		if dialog_ui.has_method("start_dialog"):
			dialog_ui.start_dialog(DIALOG_LINES, self)
		_has_talked = true
		prompt.visible = false


# ================= AUDIO CONTROL API =================
# dialog_ui will call these for each line

func play_line_audio(line_index: int) -> void:
	if line_index < 0 or line_index >= DIALOG_AUDIO.size():
		return

	if _audio_player and _audio_player.playing:
		_audio_player.stop()

	_audio_player.stream = DIALOG_AUDIO[line_index]
	_audio_player.play()


func stop_line_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
