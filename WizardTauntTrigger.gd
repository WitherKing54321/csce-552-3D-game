extends Area3D

@export var wizard_path: NodePath          # drag WIZARD here
@export var player_group: String = "player"

var _triggered := false


func _ready() -> void:
	print("WizardTauntTrigger ready at ", global_transform.origin)
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node) -> void:
	print("WizardTauntTrigger: body entered -> ", body.name)

	if _triggered:
		print("WizardTauntTrigger: already triggered, ignoring.")
		return

	if not body.is_in_group(player_group):
		print("WizardTauntTrigger: body not in group '%s', ignoring." % player_group)
		return

	_triggered = true
	print("WizardTauntTrigger: PLAYER triggered, starting wizard taunt.")
	_start_wizard_taunt()


func _start_wizard_taunt() -> void:
	var wizard := get_node_or_null(wizard_path)
	if wizard == null:
		push_warning("WizardTauntTrigger: wizard_path not set or wizard not found!")
		return

	if wizard.has_method("start_taunt"):
		print("WizardTauntTrigger: calling wizard.start_taunt().")
		wizard.start_taunt()
	else:
		push_warning("WizardTauntTrigger: wizard has no method 'start_taunt'.")
