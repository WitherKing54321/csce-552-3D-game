extends Area3D

@export var player_group := "player_global"   # set this to whatever group your player uses

# We load the SuccessMenu.tscn from the res:// folder
const SUCCESS_SCENE := preload("res://Objects/SuccessMenu.tscn")

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("Success Area ready")

func _on_body_entered(body: Node3D) -> void:
	print("Area body entered by:", body.name)

	if _triggered:
		return

	if not body.is_in_group(player_group):
		return

	_triggered = true
	_go_to_success_scene()

func _go_to_success_scene() -> void:
	print("Loading SuccessMenu.tscn...")
	get_tree().change_scene_to_packed(SUCCESS_SCENE)
