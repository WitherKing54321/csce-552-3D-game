extends Node3D

# These are wired by the scene tree, no exports needed
@onready var path_follow: PathFollow3D = $MonsterPath/MonsterPathFollow
@onready var monster_root: Node3D = $MonsterPath/MonsterPathFollow/MonsterRoot
@onready var death_area: Area3D = $MonsterPath/MonsterPathFollow/MonsterRoot/DeathArea

@export var speed: float = 8.0

var active: bool = false


func _ready() -> void:
	print("--- ChaseController: _ready ---")
	print("  path_follow =", path_follow)
	print("  monster_root =", monster_root)
	print("  death_area =", death_area)

	# Hide monster and disable death at start
	if monster_root:
		monster_root.visible = false
		monster_root.process_mode = Node.PROCESS_MODE_DISABLED
		print("  -> MonsterRoot hidden at start")
	else:
		push_error("ChaseController: MonsterRoot NOT found, check the node path")

	if death_area:
		if death_area.has_method("set_active"):
			death_area.set_active(false)
		else:
			death_area.monitoring = false
		print("  -> DeathArea disabled at start")
	else:
		push_error("ChaseController: DeathArea NOT found, check the node path")


func start_chase() -> void:
	print("--- ChaseController: START CHASE ---")

	active = true

	# Reset path to beginning
	if path_follow:
		path_follow.progress = 0.0

	# Show & enable monster
	if monster_root:
		monster_root.visible = true
		monster_root.process_mode = Node.PROCESS_MODE_INHERIT
		print("  -> MonsterRoot made visible")

	# Enable death hitbox
	if death_area and death_area.has_method("set_active"):
		death_area.set_active(true)


func _process(delta: float) -> void:
	if not active:
		return

	if path_follow:
		path_follow.progress += speed * delta
