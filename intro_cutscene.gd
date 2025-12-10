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

@export var next_scene: PackedScene

@onready var dialog_label: Label = $CutsceneLabel

var _current_line_index: int = 0

func _ready() -> void:
	if dialog_label == null:
		push_error("IntroCutscene: CutsceneLabel not found.")
		return

	if dialog_lines.is_empty():
		dialog_label.text = ""
	else:
		dialog_label.text = dialog_lines[0]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:

		# --- Q TO SKIP CUTSCENE ---
		if event.keycode == KEY_Q:
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

	_current_line_index += 1

	# Past last line → go to game
	if _current_line_index >= dialog_lines.size():
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)
		else:
			push_warning("IntroCutscene: 'next_scene' is not assigned!")
		return

	# Otherwise show next line
	dialog_label.text = dialog_lines[_current_line_index]
