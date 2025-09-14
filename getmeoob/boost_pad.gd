extends RigidBody2D
# Si tu veux le pad "poussable", change en `extends RigidBody2D` (le script reste valable).

@export var boost_power: float = 600.0
@export var boost_mode: int = 0        # 0=Forward(+X), 1=Up(-Y), 2=Custom
@export var boost_vector: Vector2 = Vector2.RIGHT
@export var face_left: bool = false    # coche ça pour flip visuel + logique

@onready var sensor: Area2D = $TopSensor

func _ready() -> void:
	sensor.body_entered.connect(_on_enter)
	# flip visuel si on a un Sprite
	if has_node("Visual/AnimatedSprite2D"):
		var sp = $"Visual/AnimatedSprite2D"
		sp.flip_h = face_left

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
