extends AudioStreamPlayer3D


# NPC dialogue player (2D or 3D), set this in the Inspector
@export var npc_dialogue_player: AudioStreamPlayer = null

# Default music volume
@export_range(-40.0, 6.0, 0.1)
var music_volume_db: float = -6.0

var _want_music: bool = true


func _ready() -> void:
	# Set starting volume
	volume_db = music_volume_db

	# We want this node to check every frame
	set_process(true)


func _process(delta: float) -> void:
	if not npc_dialogue_player:
		return

	# If dialogue is playing, cut the music
	if npc_dialogue_player.playing:
		if playing:
			stop()
		return

	# If dialogue is not playing, make sure music is playing
	if _want_music and not playing:
		volume_db = music_volume_db
		play()
