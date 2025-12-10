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


func _ready() -> void:
	add_to_group("dialog_ui")      # so everyone can find this node
	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)


# ========== PUBLIC API ==========

# Existing manual dialog – NPCs & Guide can keep using this
func start_dialog(lines: Array[String], speaker_npc: Node = null) -> void:
	if lines.is_empty():
		return

	_lines = lines.duplicate()
	_index = 0
	_active = true
	_auto_mode = false
	_speaker_npc = speaker_npc

	_show_current_line()

	dialog_panel.show()
	show()
	set_process_unhandled_input(true)


# NEW: auto-advance dialog – used by the wizard
func start_auto_dialog(lines: Array[String], seconds_per_line: float = -1.0, speaker_npc: Node = null) -> void:
	if lines.is_empty():
		return

	var duration := seconds_per_line
	if duration <= 0.0:
		duration = auto_seconds_per_line

	_lines = lines.duplicate()
	_index = 0
	_active = true
	_auto_mode = true
	_speaker_npc = speaker_npc

	_show_current_line()

	dialog_panel.show()
	show()
	set_process_unhandled_input(false)  # no input while in auto mode

	# Start the coroutine; we don't await it from here
	call_deferred("_run_auto_dialog", duration)


func is_active() -> bool:
	return _active


# Optional convenience: if something needs to instantly close the dialog
func force_close() -> void:
	if _active:
		_finish_dialog()


# ========== INTERNAL ==========

func _show_current_line() -> void:
	if _index >= 0 and _index < _lines.size():
		dialog_label.text = _lines[_index]

		# Optional audio hook: per-line audio from the speaking NPC
		if _speaker_npc and _speaker_npc.has_method("play_line_audio"):
			_speaker_npc.play_line_audio(_index)


func _next_line() -> void:
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

	# Stop any playing line audio
	if _speaker_npc and _speaker_npc.has_method("stop_line_audio"):
		_speaker_npc.stop_line_audio()
	_speaker_npc = null

	emit_signal("dialog_finished")


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	# Use your custom action mapped to E
	if event.is_action_pressed("dialog_next"):
		_next_line()
	elif event.is_action_pressed("ui_cancel"):
		_finish_dialog()



func _run_auto_dialog(seconds_per_line: float) -> void:
	_auto_dialog_coroutine(seconds_per_line)


func _auto_dialog_coroutine(seconds_per_line: float) -> void:
	while _active and _index >= 0 and _index < _lines.size():
		await get_tree().create_timer(seconds_per_line).timeout
		if not _active:
			break
		_next_line()
