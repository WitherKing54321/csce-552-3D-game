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

# Audio for each line
const DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/TimeMachine.wav"),              # 0  (quieter)
	preload("res://Sounds/Guard Line 1 Group 1.wav"),     # 1
	preload("res://Sounds/Guard Line 2 Group 1.wav"),     # 2
	preload("res://Sounds/Guard Line 3 Group 1.wav"),     # 3
	preload("res://Sounds/Guard Line 4 Group 1.wav"),     # 4
	preload("res://Sounds/Guard Line 5 Group 1.wav"),     # 5
	preload("res://Sounds/Guard Line 6 Group 1.wav"),     # 6
	preload("res://Sounds/Guard Line 7 Group 1.wav"),     # 7
	preload("res://Sounds/Torch.wav"),                    # 8
	preload("res://Sounds/Guard Line 1 Group 2.wav"),     # 9
	preload("res://Sounds/Guard Line 2 Group 2.wav"),     # 10
	preload("res://Sounds/Torch.wav"),                    # 11
	preload("res://Sounds/MonsterGuardSlam.wav")          # 12 (quieter)
]

# Volume per line (in dB) — only quieting line 0 and line 12
const DIALOG_VOLUME: Array[float] = [
	-9.0,  # TimeMachine (quieter)
	0.0,    # 1
	0.0,    # 2
	0.0,    # 3
	0.0,    # 4
	0.0,    # 5
	0.0,    # 6
	0.0,    # 7
	0.0,    # 8
	0.0,    # 9
	0.0,    # 10
	0.0,    # 11
	-7.0   # MonsterGuardSlam (quieter)
]

@export var next_scene: PackedScene

@onready var dialog_label: Label = $CutsceneLabel

var _current_line_index: int = 0
var _audio_player: AudioStreamPlayer = null


func _ready() -> void:
	if dialog_label == null:
		push_error("IntroCutscene: CutsceneLabel not found.")
		return

	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)

	if dialog_lines.is_empty():
		dialog_label.text = ""
	else:
		dialog_label.text = dialog_lines[0]
		_play_line_audio(0)

	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:

		# ---- Q → skip cutscene ----
		if event.keycode == KEY_Q:
			_stop_audio()
			if next_scene:
				get_tree().change_scene_to_packed(next_scene)
			else:
				push_warning("IntroCutscene: next_scene not assigned!")
			return

		# ---- SPACE or ENTER → next line ----
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance_dialog()


func _advance_dialog() -> void:
	if dialog_label == null:
		return

	_stop_audio()

	_current_line_index += 1

	if _current_line_index >= dialog_lines.size():
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)
		else:
			push_warning("IntroCutscene: next_scene not assigned!")
		return

	dialog_label.text = dialog_lines[_current_line_index]
	_play_line_audio(_current_line_index)


func _play_line_audio(line_index: int) -> void:
	if _audio_player == null:
		return

	if line_index < 0 or line_index >= DIALOG_AUDIO.size():
		return

	_audio_player.stop()

	_audio_player.stream = DIALOG_AUDIO[line_index]

	# Apply per-line volume
	if line_index < DIALOG_VOLUME.size():
		_audio_player.volume_db = DIALOG_VOLUME[line_index]
	else:
		_audio_player.volume_db = 0.0

	_audio_player.play()


func _stop_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
