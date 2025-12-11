extends Area3D

@export var chase_controller: Node3D   # set per trigger in Inspector

# Preload your chase music wav
const CHASE_MUSIC: AudioStream = preload("res://Sounds/ChaseMusic.wav")

var _triggered := false
var _music_player: AudioStreamPlayer = null


func _ready() -> void:
	print("ChaseTrigger READY on node:", get_path())
	print("  chase_controller set to:", chase_controller)

	monitoring = true     # just to be safe
	monitorable = true

	body_entered.connect(_on_body_entered)

	# Create a non positional audio player for chase music
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -10
	_music_player.autoplay = false
	add_child(_music_player)


func _on_body_entered(body: Node3D) -> void:
	print("ChaseTrigger body_entered on:", get_path())
	print("  body:", body.name, "  triggered:", _triggered)

	if _triggered:
		print("  -> already triggered, ignoring")
		return

	if not body.is_in_group("player"):
		print("  -> body is NOT in group 'player', ignoring")
		return

	_triggered = true
	print("  -> PLAYER entered trigger, starting chase")
	print("  chase_controller =", chase_controller)

	# Start chase logic
	if chase_controller and chase_controller.has_method("start_chase"):
		chase_controller.start_chase()
	else:
		push_error("ChaseTrigger ERROR: chase_controller is NOT set or has no start_chase()")

	# Start chase music
	if _music_player and CHASE_MUSIC:
		_music_player.stream = CHASE_MUSIC
		_music_player.play()
