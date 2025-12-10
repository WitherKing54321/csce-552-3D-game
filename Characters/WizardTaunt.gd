extends Node3D

# Wizard's taunt lines during the second chase
const TAUNT_DIALOG_LINES: Array[String] = [
	"You were doomed the moment you stepped into this castle!",
	"My Knight hunts without mercy, and you are far too slow to escape it.",
	"Your end will be quick, but not painless."
]

@export var seconds_per_line: float = 3.0    # how long each line stays on screen

var _has_taunt_played: bool = false


func start_taunt() -> void:
	if _has_taunt_played:
		print("WizardTaunt: taunt already played, ignoring.")
		return

	print("WizardTaunt: start_taunt called.")

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("WizardTaunt: No node in group 'dialog_ui' found for TAUNT dialog.")
		return

	# If you want to be extra safe about overlapping dialog, you could add:
	# if dialog_ui.has_method("is_active") and dialog_ui.is_active(): return

	# Use the new auto-dialog mode
	if dialog_ui.has_method("start_auto_dialog"):
		dialog_ui.start_auto_dialog(TAUNT_DIALOG_LINES, seconds_per_line)
	elif dialog_ui.has_method("start_dialog"):
		# Fallback: manual, just in case
		dialog_ui.start_dialog(TAUNT_DIALOG_LINES)
	else:
		push_warning("WizardTaunt: dialog_ui has no start_auto_dialog() or start_dialog().")
		return

	_has_taunt_played = true
	print("WizardTaunt: taunt dialog started (auto).")
