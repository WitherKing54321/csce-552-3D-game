extends Node3D

@export var one_time_only := true
@export var player_group := "player"
@export var prompt_text := "Press [E] to receive a sword"
@export var auto_face_player := true   # turn to face the nearby player

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Label3D
@onready var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var npc_root: Node3D = $MeshInstance3D

var _player_in_range: Node3D = null
var _given := false

func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if auto_face_player and _player_in_range and is_instance_valid(_player_in_range):
		var to_player: Vector3 = (_player_in_range.global_transform.origin - global_transform.origin)
		to_player.y = 0.0
		if to_player.length() > 0.01:
			var target_yaw := atan2(to_player.x, to_player.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, 6.0 * delta)

	if _player_in_range and Input.is_action_just_pressed("interact"):
		_try_give_sword(_player_in_range)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(player_group):
		return
	_player_in_range = body
	if not _given:
		prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null
	prompt.visible = false

func _try_give_sword(player: Node) -> void:
	if _given and one_time_only:
		return
	if not is_instance_valid(player):
		return
	if "give_sword" in player:
		player.give_sword()
		if sfx:
			sfx.play()
		_given = true
		prompt.visible = false
		prompt.text = "Safe travels!"
	else:
		push_warning("Player is missing give_sword(); add it to your Player.gd.")
