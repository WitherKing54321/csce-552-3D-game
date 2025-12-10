extends Area3D

# Player group to detect
@export var player_group := "player"

# Have we already played this dialog?
var _has_played: bool = false

# Third dialog set that should play at the bottom of the staircase
const END_DIALOG_LINES: Array[String] = [
	"This is as far as I go.",
	"From here on, you're on your own.",
	"Stay quiet... and whatever happens, don't stop moving."
]


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _has_played:
		return
	if not body.is_in_group(player_group):
		return

	var dialog_ui := get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui == null:
		push_warning("StairDialogTrigger: No node in group 'dialog_ui' found.")
		return

	# If your dialog UI exposes is_active(), wait for any current dialog to finish
	if dialog_ui.has_method("is_active"):
		while dialog_ui.is_active():
			await get_tree().create_timer(0.1).timeout

	if dialog_ui.has_method("start_dialog"):
		dialog_ui.start_dialog(END_DIALOG_LINES)
		_has_played = true
	else:
		push_warning("StairDialogTrigger: dialog_ui is missing start_dialog().")

	# Optional: remove the trigger so it never fires again
	# queue_free()
