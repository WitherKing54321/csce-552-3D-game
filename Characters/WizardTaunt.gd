extends Node3D

# Wizard's taunt lines during the second chase
const TAUNT_DIALOG_LINES: Array[String] = [
	"You were doomed the moment you stepped into this castle!",
	"My Knight hunts without mercy, and you are far too slow to escape it.",
	"Your end will be quick, but not painless."
]

# One audio clip per line (change paths to your actual wavs)
const TAUNT_DIALOG_AUDIO: Array[AudioStream] = [
	preload("res://Sounds/Wizard Line 1.wav"),
	preload("res://Sounds/Wizard Line 2.wav"),
	preload("res://Sounds/Wizard Line 3.wav")
]

# How long EACH line stays on screen (seconds), in order.
@export var taunt_line_durations: Array[float] = [3.2, 5.3, 4.0]

# Volume per line in dB (0.0 = normal, negative is quieter, positive is louder)
@export var taunt_line_volumes: Array[float] = [5.0, 05.0, 5.0]

# Resolve the AnimationPlayer in _ready() so we can log or handle missing nodes safely
@onready var _anim: AnimationPlayer = null
var _has_taunt_played: bool = false

# Non positional audio - will be heard anywhere
var _audio_player: AudioStreamPlayer = null


func _ready() -> void:
	# If the AnimationPlayer is a direct child of this WIZARD node:
	_anim = get_node_or_null("AnimationPlayer") as AnimationPlayer

	if _anim:
		print("WizardTaunt: AnimationPlayer found:", _anim)
	else:
		push_warning("WizardTaunt: AnimationPlayer not found at 'AnimationPlayer' (adjust path in _ready()).")

	# Create non 3D audio player in code so volume is not based on distance
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)

	# Safety: make sure durations and volumes lists match line count
	_sync_durations_size()
	_sync_volumes_size()


func _sync_durations_size() -> void:
	# Ensure we have one duration per line; fill missing with 3.0s
	if taunt_line_durations.size() < TAUNT_DIALOG_LINES.size():
		var missing := TAUNT_DIALOG_LINES.size() - taunt_line_durations.size()
		for i in range(missing):
			taunt_line_durations.append(3.0)
	elif taunt_line_durations.size() > TAUNT_DIALOG_LINES.size():
		taunt_line_durations.resize(TAUNT_DIALOG_LINES.size())


func _sync_volumes_size() -> void:
	# Ensure we have one volume per line; fill missing with 0.0 dB
	if taunt_line_volumes.size() < TAUNT_DIALOG_LINES.size():
		var missing := TAUNT_DIALOG_LINES.size() - taunt_line_volumes.size()
		for i in range(missing):
			taunt_line_volumes.append(0.0)
	elif taunt_line_volumes.size() > TAUNT_DIALOG_LINES.size():
		taunt_line_volumes.resize(TAUNT_DIALOG_LINES.size())


func start_taunt() -> void:
	# Do not start twice
	if _has_taunt_played:
		print("WizardTaunt: taunt already played, ignoring.")
		return

	# Play animation only if found
	if _anim:
		_anim.play("ArmatureAction")
	else:
		push_warning("WizardTaunt: cannot play animation - AnimationPlayer is null")

	print("WizardTaunt: start_taunt called.")

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("WizardTaunt: No node in group 'dialog_ui' found for TAUNT dialog.")
		return

	_sync_durations_size()
	_sync_volumes_size()

	# Prefer auto dialog mode that advances on a timer
	# Contract: start_auto_dialog(lines: Array[String], durations: Array[float], speaker: Node)
	if dialog_ui.has_method("start_auto_dialog"):
		dialog_ui.start_auto_dialog(TAUNT_DIALOG_LINES, taunt_line_durations, self)
	elif dialog_ui.has_method("start_dialog"):
		# Fallback manual dialog with the same audio hookup
		dialog_ui.start_dialog(TAUNT_DIALOG_LINES, self)
	else:
		push_warning("WizardTaunt: dialog_ui has no start_auto_dialog() or start_dialog().")
		return

	_has_taunt_played = true
	print("WizardTaunt: taunt dialog started.")


# ============ AUDIO API FOR dialog_ui ============

func play_line_audio(line_index: int) -> void:
	if _audio_player == null:
		return
	if line_index < 0 or line_index >= TAUNT_DIALOG_AUDIO.size():
		return

	if _audio_player.playing:
		_audio_player.stop()

	_audio_player.stream = TAUNT_DIALOG_AUDIO[line_index]

	# Set per line volume if available
	if line_index >= 0 and line_index < taunt_line_volumes.size():
		_audio_player.volume_db = taunt_line_volumes[line_index]
	else:
		_audio_player.volume_db = 0.0  # default

	_audio_player.play()


func stop_line_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
