extends Control

@export var dialog_lines: Array[String] = [
	"*ELECTRONICAL WHIRRING*",
	"What is that thing?!",
	"Whatever it is, it looks dangerous.",
	"Go check it out.",
	"It's like some sort of metal container...",
	"There's someone inside of it!",
	"Grab him, and take him to the dungeon!",
	"Aye sir!",
	"...30 MINUTES LATER...",
	"This guy... his attire is odd and shabby, and he smells terrible.",
	"You think I care about that? He's an intruder, and I am going to make him pay!",
	"...5 MINUTES LATER...",
	"*ROAR* *SCREAM* *CRASH*"
]

# Audio for each line - change file paths to your own wavs
const DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/TimeMachine.wav"),
	preload("res://Sounds/Guard Line 1 Group 1.wav"),
	preload("res://Sounds/Guard Line 2 Group 1.wav"),
	preload("res://Sounds/Guard Line 3 Group 1.wav"),
	preload("res://Sounds/Guard Line 4 Group 1.wav"),
	preload("res://Sounds/Guard Line 5 Group 1.wav"),
	preload("res://Sounds/Guard Line 6 Group 1.wav"),
	preload("res://Sounds/Guard Line 7 Group 1.wav"),
	preload("res://Sounds/Torch.wav"),
	preload("res://Sounds/Guard Line 1 Group 2.wav"),
	preload("res://Sounds/Guard Line 2 Group 2.wav"),
	preload("res://Sounds/Torch.wav"),
	preload("res://Sounds/MonsterGuardSlam.wav")
]

@export var next_scene: PackedScene

@onready var dialog_label: Label = $CutsceneLabel

var _current_line_index: int = 0
var _audio_player: AudioStreamPlayer = null


func _ready() -> void:
	if dialog_label == null:
		push_error("IntroCutscene: CutsceneLabel not found.")
		return

	# Create audio player in code so no node is needed in the scene
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)

	if dialog_lines.is_empty():
		dialog_label.text = ""
	else:
		dialog_label.text = dialog_lines[0]
		_play_line_audio(0)

	# Make sure we receive unhandled input
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:

		# --- Q TO SKIP CUTSCENE ---
		if event.keycode == KEY_Q:
			_stop_audio()
			if next_scene:
				get_tree().change_scene_to_packed(next_scene)
			else:
				push_warning("IntroCutscene: 'next_scene' is not assigned!")
			return

		# SPACE or ENTER → advance dialog
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance_dialog()


func _advance_dialog() -> void:
	if dialog_label == null:
		return

	# Stop current line audio before moving on
	_stop_audio()

	_current_line_index += 1

	# Past last line → go to game
	if _current_line_index >= dialog_lines.size():
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)
		else:
			push_warning("IntroCutscene: 'next_scene' is not assigned!")
		return

	# Otherwise show next line and play its audio
	dialog_label.text = dialog_lines[_current_line_index]
	_play_line_audio(_current_line_index)


func _play_line_audio(line_index: int) -> void:
	if _audio_player == null:
		return

	# Safe guard if you have fewer audio clips than lines
	if line_index < 0 or line_index >= DIALOG_AUDIO.size():
		return

	if _audio_player.playing:
		_audio_player.stop()

	_audio_player.stream = DIALOG_AUDIO[line_index]
	_audio_player.play()


func _stop_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
