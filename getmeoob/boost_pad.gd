extends RigidBody2D
# Si tu veux le pad "poussable", change en `extends RigidBody2D` (le script reste valable).

@export var boost_power: float = 600.0
@export var boost_mode: int = 0        # 0=Forward(+X), 1=Up(-Y), 2=Custom
@export var boost_vector: Vector2 = Vector2.RIGHT
@export var face_left: bool = false    # coche ça pour flip visuel + logique
@export var freeze_rotation: bool = true
@export var lock_y_always: bool = true
@export var player_group: String = "player"

var _x_lock:= 0.0
var _y_lock := 0.0
var _top_contacts: int = 0
var _lock_x_activate: bool = false

@onready var sensor: Area2D = $TopSensor

func _ready() -> void:
	sensor.body_entered.connect(_on_enter)
	_y_lock = global_position.y
	gravity_scale = 0.0
	if sensor:
		sensor.body_entered.connect(_on_top_enter)
		sensor.body_exited.connect(_on_top_exit)
	# flip visuel si on a un Sprite
	if has_node("Visual/AnimatedSprite2D"):
		var sp = $"Visual/AnimatedSprite2D"
		sp.flip_h = face_left
		
func _on_top_enter(body: Node) -> void:
	 # Mieux : mets ton Player dans le groupe "player"
	if body.is_in_group(player_group):
		_top_contacts += 1
		if not _lock_x_activate:
			_x_lock = global_position.x
			_lock_x_activate = true
		
func _on_top_exit(body: Node) -> void:
	if body.is_in_group(player_group):
		_top_contacts = max(0, _top_contacts - 1)
		if _top_contacts == 0:
			_lock_x_activate = false

func _on_enter(body: Node) -> void:
	var dir := _boost_dir()
	if body.has_method("apply_boost"):
		body.apply_boost(dir, boost_power, 0.25)
	elif "velocity" in body:
		body.velocity += dir * boost_power

func _boost_dir() -> Vector2:
	var base := Vector2.ZERO
	if boost_mode == 0:
		base = Vector2.RIGHT.rotated(global_rotation)  # suit la rotation du pad
	elif boost_mode == 1:
		base = Vector2.UP.rotated(global_rotation)
	else:
		base = boost_vector.rotated(global_rotation)

	if face_left:
		base = -base
	return base.normalized()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if freeze_rotation:
		angular_velocity = 0.0
		rotation = 0.0  # garde le pad bien plat

	# Amortir très fort la vitesse verticale (garde le X libre pour pousser)
	if lock_y_always:
		# annule tout mouvement vertical
		linear_velocity.y = 0.0
		# recale la position (au cas où un contact l’aurait poussée en Y)
		var p := global_position
		p.y = _y_lock
		global_position = p
	 # Tant que le joueur est "au-dessus", on amortit très fort la vitesse horizontale
	if _lock_x_activate:
		linear_velocity.x = 0.0
		var p2 := global_position
		p2.x = _x_lock
		global_position = p2
