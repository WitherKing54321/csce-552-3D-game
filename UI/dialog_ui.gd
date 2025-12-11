extends CanvasLayer

signal dialog_finished

@export var auto_seconds_per_line: float = 3.0

@onready var dialog_panel: Control = $DialogPanel
@onready var dialog_label: Label = $DialogPanel/MarginContainer/DialogLabel

var _lines: Array[String] = []
var _index: int = 0
var _active: bool = false
var _auto_mode: bool = false
var _speaker_npc: Node = null   # NPC that owns audio for these lines (if any)

var _durations: Array[float] = []      # optional per line durations
var _auto_default_duration: float = 0  # fallback when not using per line durations


func _ready() -> void:
	add_to_group("dialog_ui")      # so everyone can find this node
	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)


# ========== PUBLIC API ==========

# Manual dialog, player presses button to advance
func start_dialog(lines: Array[String], speaker_npc: Node = null) -> void:
	if lines.is_empty():
		return

	_lines = lines.duplicate()
	_index = 0
	_active = true
	_auto_mode = false
	_speaker_npc = speaker_npc
	_durations.clear()
	_auto_default_duration = 0.0

	_show_current_line()

	dialog_panel.show()
	show()
	set_process_unhandled_input(true)


# Auto advance dialog
# durations_or_seconds can be:
#  - Array[float]  -> per line durations
#  - float / int   -> same duration for all lines
#  - omitted or <= 0 -> uses auto_seconds_per_line
func start_auto_dialog(lines: Array[String], durations_or_seconds = -1.0, speaker_npc: Node = null) -> void:
	if lines.is_empty():
		return

	_lines = lines.duplicate()
	_index = 0
	_active = true
	_auto_mode = true
	_speaker_npc = speaker_npc
	_durations.clear()

	if durations_or_seconds is Array:
		# Per line durations
		for v in durations_or_seconds:
			_durations.append(float(v))
		# Resize or pad so it matches number of lines
		if _durations.size() < _lines.size():
			var missing := _lines.size() - _durations.size()
			for i in range(missing):
				_durations.append(auto_seconds_per_line)
		elif _durations.size() > _lines.size():
			_durations.resize(_lines.size())
		_auto_default_duration = auto_seconds_per_line
	else:
		# Single duration for all lines
		var dur: float = float(durations_or_seconds)
		if dur <= 0.0:
			dur = auto_seconds_per_line
		_auto_default_duration = dur

	_show_current_line()

	dialog_panel.show()
	show()
	set_process_unhandled_input(false)  # no input needed in auto mode

	# Start the coroutine after draw
	call_deferred("_run_auto_dialog")


func is_active() -> bool:
	return _active


func force_close() -> void:
	if _active:
		_finish_dialog()


# ========== INTERNAL ==========

func _show_current_line() -> void:
	if _index >= 0 and _index < _lines.size():
		dialog_label.text = _lines[_index]

		if _speaker_npc and _speaker_npc.has_method("play_line_audio"):
			_speaker_npc.play_line_audio(_index)


func _next_line() -> void:
	# Stop current line audio before moving on
	if _speaker_npc and _speaker_npc.has_method("stop_line_audio"):
		_speaker_npc.stop_line_audio()

	_index += 1
	if _index >= _lines.size():
		_finish_dialog()
	else:
		_show_current_line()


func _finish_dialog() -> void:
	_active = false
	_auto_mode = false
	_lines.clear()
	_index = 0

	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)

	if _speaker_npc and _speaker_npc.has_method("stop_line_audio"):
		_speaker_npc.stop_line_audio()
	_speaker_npc = null

	_durations.clear()
	_auto_default_duration = 0.0

	emit_signal("dialog_finished")


func _unhandled_input(event: InputEvent) -> void:
	if not _active or _auto_mode:
		return

	if event.is_action_pressed("dialog_next"):
		_next_line()
	elif event.is_action_pressed("ui_cancel"):
		_finish_dialog()


func _run_auto_dialog() -> void:
	_auto_dialog_coroutine()


func _auto_dialog_coroutine() -> void:
	while _active and _index >= 0 and _index < _lines.size():
		var wait_time: float

		if _durations.size() > 0 and _index < _durations.size():
			wait_time = _durations[_index]
		elif _auto_default_duration > 0.0:
			wait_time = _auto_default_duration
		else:
			wait_time = auto_seconds_per_line

		await get_tree().create_timer(wait_time).timeout
		if not _active:
			break

		_next_line()
