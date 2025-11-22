extends CanvasLayer

signal dialog_finished

@onready var dialog_panel: Control = $DialogPanel
@onready var dialog_label: Label = $DialogPanel/MarginContainer/DialogLabel

var _lines: Array[String] = []
var _index: int = 0
var _active: bool = false

func _ready() -> void:
	add_to_group("dialog_ui")
	dialog_panel.hide()
	hide()

func is_active() -> bool:
	return _active

func start_dialog(lines: Array[String]) -> void:
	if lines.is_empty():
		return

	_lines = lines
	_index = 0
	_active = true

	show()
	dialog_panel.show()
	_show_current_line()

func _show_current_line() -> void:
	dialog_label.text = _lines[_index]

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	# ONLY Enter (dialog_next) can advance dialog.
	# Spacebar must NOT affect dialog at all.
	if event.is_action_pressed("dialog_next"):
		_index += 1

		if _index >= _lines.size():
			_finish_dialog()
		else:
			_show_current_line()

func _finish_dialog() -> void:
	_active = false
	dialog_panel.hide()
	hide()
	emit_signal("dialog_finished")
