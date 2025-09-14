extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var ground_accel: float = 2200.0
@export var air_accel: float = 1400.0
@export var ground_friction: float = 4000.0   # ↑ augmente pour stopper plus sec
@export var air_friction: float = 800.0
@export var landing_dampen: float = 0.6       # 0..1 : casse l’élan à l’atterrissage
@export var stop_threshold: float = 10.0      # met vite la vitesse à 0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var last_movement: String = "left"
var boost_time: float = 0.0
var _was_on_floor: bool = false

# Appelé par le boost pad
func apply_boost(dir: Vector2, power: float, duration: float = 0.25) -> void:
	var d := dir.normalized()
	velocity += d * power
	boost_time = max(boost_time, duration)
	if d.x != 0.0:
		if d.x > 0.0:
			last_movement = "right"
		else:
			last_movement = "left"

func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Détection d'atterrissage : casser un peu l'élan horizontal
	var just_landed := is_on_floor() and not _was_on_floor
	if just_landed:
		velocity.x *= landing_dampen

	# Saut
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Dive (descente rapide)
	if Input.is_action_just_pressed("move_down") and not is_on_floor():
		velocity.y = -jump_velocity  # jump_velocity est négatif → -(-400)=+400 descend

	# Input horizontal
	var direction := Input.get_axis("move_left", "move_right")

	# -------- Animations (inchangées) --------
	if direction > 0.0:
		animated_sprite.play("Run_Right")
		last_movement = "right"
	elif direction < 0.0:
		animated_sprite.play("Run_Left")
		last_movement = "left"
	else:
		if last_movement == "right":
			animated_sprite.play("Idle_Right")
		else:
			animated_sprite.play("Idle_Left")
	# -----------------------------------------

	# Accélération / friction avec protection du boost
	var accel: float
	if is_on_floor():
		accel = ground_accel
	else:
		accel = air_accel

	if direction != 0.0:
		var target := direction * speed
		# Si boost actif dans le même sens et vitesse > speed, on réduit la décélération
		if boost_time > 0.0 and sign(velocity.x) == sign(direction) and abs(velocity.x) > abs(target):
			velocity.x = move_toward(velocity.x, target, accel * 0.25 * delta)
		else:
			velocity.x = move_toward(velocity.x, target, accel * delta)
	else:
		# Pas d'input → on freine. Pendant le boost, on évite de casser l’impulsion.
		if boost_time <= 0.0:
			var f := ground_friction
			if not is_on_floor():
				f = air_friction
			velocity.x = move_toward(velocity.x, 0.0, f * delta)
			if abs(velocity.x) < stop_threshold:
				velocity.x = 0.0

	move_and_slide()

	# Timers/états
	if boost_time > 0.0:
		boost_time = max(0.0, boost_time - delta)
	_was_on_floor = is_on_floor()
