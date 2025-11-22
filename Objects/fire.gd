extends Node3D

@onready var light: OmniLight3D = $OmniLight3D

@export var base_energy: float = 15.0        # normal brightness
@export var flicker_strength: float = 5.0    # how much it can vary (+/-)
@export var change_interval: float = 0.08    # how often to pick a new target
@export var flicker_smoothness: float = 10.0 # how fast it lerps toward target

var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _target_energy: float = 0.0

func _ready() -> void:
	_rng.randomize()
	_target_energy = base_energy
	if light:
		light.energy = base_energy

func _process(delta: float) -> void:
	if not light:
		return

	# pick a new target every change_interval seconds
	_timer -= delta
	if _timer <= 0.0:
		_timer = change_interval
		_target_energy = base_energy + _rng.randf_range(-flicker_strength, flicker_strength)

	# smoothly move toward target
	light.energy = lerp(light.energy, _target_energy, delta * flicker_smoothness)
