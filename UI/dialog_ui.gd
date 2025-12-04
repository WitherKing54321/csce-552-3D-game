extends CanvasLayer

signal dialog_finished

@onready var dialog_panel: Control = $DialogPanel
@onready var dialog_label: Label = $DialogPanel/MarginContainer/DialogLabel

var _lines: Array[String] = []
var _index: int = 0
var _active: bool = false
var _speaker_npc: Node = null   # NPC that owns the audio for these lines


func _ready() -> void:
	# So NPCs can find this node with get_first_node_in_group("dialog_ui")
	add_to_group("dialog_ui")
	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)


# NEW: optional speaker_npc argument
func start_dialog(lines: Array[String], speaker_npc: Node = null) -> void:
	# Always use ONLY the lines passed in from the NPC
	if lines.is_empty():
		return

	_lines = lines.duplicate()
	_index = 0
	_active = true
	_speaker_npc = speaker_npc

	_show_current_line()
	dialog_panel.show()
	show()
	set_process_unhandled_input(true)


func is_active() -> bool:
	return _active


func force_close() -> void:
	if not _active:
		return
	_finish_dialog()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("dialog_next"):
		_advance_line()
		get_viewport().set_input_as_handled()


func _advance_line() -> void:
	# Stop current line audio if any, since we are about to move on
	if _speaker_npc and _speaker_npc.has_method("stop_line_audio"):
		_speaker_npc.stop_line_audio()

	_index += 1

	if _index >= _lines.size():
		_finish_dialog()
	else:
		_show_current_line()


func _show_current_line() -> void:
	if _index >= 0 and _index < _lines.size():
		dialog_label.text = _lines[_index]

		# Tell the NPC to play audio for this line index
		if _speaker_npc and _speaker_npc.has_method("play_line_audio"):
			_speaker_npc.play_line_audio(_index)


func _finish_dialog() -> void:
	_active = false
	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)

	# Make sure audio stops when dialog ends or is forced closed
	if _speaker_npc and _speaker_npc.has_method("stop_line_audio"):
		_speaker_npc.stop_line_audio()
	_speaker_npc = null

	emit_signal("dialog_finished")
