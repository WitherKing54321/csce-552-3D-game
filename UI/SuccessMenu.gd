extends CanvasLayer

@onready var retry_button: Button = $Panel/CenterContainer/VBoxContainer/Retry
@onready var quit_button: Button  = $Panel/CenterContainer/VBoxContainer/Quit

# Preload your wav here
const SHOW_SFX: AudioStream = preload("res://Sounds/3D-Game_PianoMusic.wav")

@export_range(-40.0, 6.0, 0.1)
var sfx_volume_db: float = 0.0

var _sfx_player: AudioStreamPlayer = null


func _ready() -> void:
	# Play sound when this UI appears
	if SHOW_SFX:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.stream = SHOW_SFX
		_sfx_player.volume_db = sfx_volume_db
		add_child(_sfx_player)
		_sfx_player.play()

	# Make sure game is NOT paused, so UI can get input
	get_tree().paused = false

	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	set_process(true)

	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	retry_button.grab_focus()


func _process(_delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_retry_pressed() -> void:
	print("SuccessMenu: Retry pressed")
	_go_to_main_menu()


func _on_quit_pressed() -> void:
	print("SuccessMenu: Quit pressed")
	get_tree().quit()


func _go_to_main_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://MainMenu.tscn")
