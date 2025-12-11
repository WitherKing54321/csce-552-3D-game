extends Node3D

const DIALOG_LINES: Array[String] = [
	"*YELP*",
	"I didn't see you there...",
	"How did you make it here?!",
	"I am not leaving this spot!",
	"We are all going to die..."
]

# One audio clip per line above (change paths to your actual wavs)
const DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/ScaredNPC Line 1.wav"),
	preload("res://Sounds/ScaredNPC Line 2.wav"),
	preload("res://Sounds/ScaredNPC Line 3.wav"),
	preload("res://Sounds/ScaredNPC Line 4.wav"),
	preload("res://Sounds/ScaredNPC Line 5.wav")
]

@export var player_group := "player"
@export var prompt_text := "Press E to talk"

# NEW: volume controls
@export var default_volume_db: float = 0.0   # volume for all normal lines
@export var yelp_volume_db: float = -12.0     # volume just for "*YELP*" (line 0)

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Label3D
@onready var anim: AnimationPlayer = $scaredgaurd/AnimationPlayer

var _player_in_range: Node3D = null
var _has_talked: bool = false
var _audio_player: AudioStreamPlayer3D = null


func _ready() -> void:
	anim.play("ArmatureAction")
	prompt.text = prompt_text
	prompt.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	# Create 3D audio player in code
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.volume_db = default_volume_db
	add_child(_audio_player)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_in_range = body
		prompt.visible = not _has_talked


func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false

		# Stop any line audio when player leaves
		stop_line_audio()

		var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
		if dialog_ui and dialog_ui.has_method("is_active") and dialog_ui.is_active():
			if dialog_ui.has_method("force_close"):
				dialog_ui.force_close()
			elif dialog_ui is CanvasItem:
				dialog_ui.hide()


func _process(_delta: float) -> void:
	if _player_in_range == null:
		return

	# One time only
	if _has_talked:
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		return

	if dialog_ui.has_method("is_active") and dialog_ui.is_active():
		return

	if Input.is_action_just_pressed("dialog_next"):
		if dialog_ui.has_method("start_dialog"):
			# Pass self so dialog_ui can call play_line_audio / stop_line_audio
			dialog_ui.start_dialog(DIALOG_LINES, self)
		_has_talked = true
		prompt.visible = false


# ============ AUDIO API FOR dialog_ui ============

func play_line_audio(line_index: int) -> void:
	if _audio_player == null:
		return
	if line_index < 0 or line_index >= DIALOG_AUDIO.size():
		return

	if _audio_player.playing:
		_audio_player.stop()

	# Set volume based on which line is playing
	if line_index == 0:
		_audio_player.volume_db = yelp_volume_db
	else:
		_audio_player.volume_db = default_volume_db

	_audio_player.stream = DIALOG_AUDIO[line_index]
	_audio_player.play()


func stop_line_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
