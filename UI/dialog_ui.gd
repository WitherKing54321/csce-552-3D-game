extends CanvasLayer

signal dialog_finished

@onready var dialog_panel: Control = $DialogPanel
@onready var dialog_label: Label = $DialogPanel/MarginContainer/DialogLabel

var _lines: Array[String] = []
var _index: int = 0
var _active: bool = false

func _ready() -> void:
	add_to_group("dialog_ui")      # so other scripts can find this node
	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)

# --- PUBLIC API --- #

func start_dialog(lines: Array[String]) -> void:
	if lines.is_empty():
		return

	_lines = lines
	_index = 0
	_active = true

	dialog_panel.show()
	show()
	set_process_unhandled_input(true)
	_show_current_line()


func is_active() -> bool:
	return _active


# Force-close the dialog (used when player leaves the area)
# IMPORTANT: this does NOT emit dialog_finished,
# so "one-time" logic is ONLY triggered when a full dialog finishes.
func force_close() -> void:
	if not _active:
		return

	_active = false
	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)


# --- INTERNAL INPUT / FLOW --- #

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("dialog_next"):
		_index += 1
		if _index >= _lines.size():
			_finish_dialog()
		else:
			_show_current_line()


func _show_current_line() -> void:
	if _index >= 0 and _index < _lines.size():
		dialog_label.text = _lines[_index]


func _finish_dialog() -> void:
	_active = false
	dialog_panel.hide()
	hide()
	set_process_unhandled_input(false)
	emit_signal("dialog_finished")
