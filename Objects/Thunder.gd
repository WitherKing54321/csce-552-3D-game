extends Node3D
class_name ThunderController

@export var thunder_stream: AudioStream
@export var thunder_volume_db: float = 0.0
@export var thunder_delay_seconds: float = 1.0   # delay after lightning burst

var _player: AudioStreamPlayer3D
var _pending_thunder: bool = false   # prevent stacking multiple delayed thunders


func _ready() -> void:
	# Create audio player
	_player = AudioStreamPlayer3D.new()
	add_child(_player)
	_player.autoplay = false
	_player.stream = thunder_stream
	_player.volume_db = thunder_volume_db

	# Wait one frame so FlashPane has time to choose its master
	await get_tree().process_frame

	if FlashPane._master:
		FlashPane._master.lightning_flash.connect(_on_lightning_flash)
	else:
		push_warning("ThunderController: no FlashPane master found; thunder will not trigger.")


func _on_lightning_flash() -> void:
	# Only schedule one thunder per burst, even if somehow multiple signals arrive
	if _pending_thunder:
		return
	_pending_thunder = true
	_play_thunder_delayed()


func _play_thunder_delayed() -> void:
	# Wait the configured delay (this pauses with the game)
	await get_tree().create_timer(thunder_delay_seconds).timeout

	# If the game is paused at that exact moment, wait until unpaused
	while get_tree().paused:
		await get_tree().process_frame

	if thunder_stream == null:
		push_warning("ThunderController: thunder_stream is not assigned.")
		_pending_thunder = false
		return

	_player.stream = thunder_stream
	_player.volume_db = thunder_volume_db
	_player.play()

	_pending_thunder = false
