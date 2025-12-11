extends Node3D

# ================= DIALOG TEXT =================
const DIALOG_LINES: Array[String] = [
	"Where did you come from?",
	"Oh, it doesn't matter, but watch out...",
	"I've heard a lot of screaming today..."
]

# ================= DIALOG AUDIO =================
const DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/ShopKeep Line 1 .wav"),
	preload("res://Sounds/ShopKeep Line 2.wav"),
	preload("res://Sounds/ShopKeep Line 3.wav")
]

@export var player_group := "player"
@export var prompt_text := "Press E to talk"

# Nodes
@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Label3D
@onready var anim: AnimationPlayer = $shopkeep4/AnimationPlayer  # make sure this node exists

var _player_in_range: Node3D = null
var _has_talked: bool = false
var _audio_player: AudioStreamPlayer3D = null

func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	_audio_player = AudioStreamPlayer3D.new()
	add_child(_audio_player)

	# Connect animation finished signal so we can react when talk animation ends
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
		# Start idle animation (if it exists)
		if anim.has_animation("shopkeep_idle_001"):
			anim.play("shopkeep_idle_001")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_in_range = body
		if not _has_talked:
			prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false
		stop_line_audio()

		var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
		if dialog_ui and dialog_ui.has_method("is_active") and dialog_ui.is_active():
			if dialog_ui.has_method("force_close"):
				dialog_ui.force_close()
			elif dialog_ui is CanvasItem:
				dialog_ui.hide()


func _process(delta: float) -> void:
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
		
		# Call dialog system
		if dialog_ui.has_method("start_dialog"):
			dialog_ui.start_dialog(DIALOG_LINES, self)

		# --- Switch to talk animation ---
		if anim and anim.has_animation("shopkeep_talk_001"):
			anim.play("shopkeep_talk_001")

		_has_talked = true
		prompt.visible = false


func play_line_audio(index: int) -> void:
	if index >= 0 and index < DIALOG_AUDIO.size():
		_audio_player.stream = DIALOG_AUDIO[index]
		_audio_player.play()


func stop_line_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()


# === CALLED BY DIALOG UI when dialog ends ===
func dialog_finished() -> void:
	# Ensure audio stopped and return to idle
	stop_line_audio()
	if anim and anim.has_animation("newidle"):
		anim.play("newidle")


# Called when any animation finishes
func _on_animation_finished(anim_name: String) -> void:
	# If the talk animation finished, ensure we return to idle (but only if idle exists)
	if anim_name == "talkidle":
		if anim and anim.has_animation("newidle"):
			anim.play("newidle")
