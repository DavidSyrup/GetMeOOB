extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var ground_accel: float = 2200.0
@export var air_accel: float = 1400.0
@export var ground_friction: float = 4000.0   # ↑ augmente pour stopper plus sec
@export var air_friction: float = 800.0
@export var landing_dampen: float = 0.6       # 0..1 : casse l’élan à l’atterrissage
@export var stop_threshold: float = 10.0      # met vite la vitesse à 0

# --- Début : paramètres de poussée (réglables dans l’inspector) ---
@export var can_push_only_on_floor: bool = true
@export var push_impulse: float = 160.0      # intensité des coups d’épaule
@export var push_cooldown: float = 0.05      # toutes les X s on ré-applique l’impulsion
@export var push_side_angle: float = 0.4     # |normal.y| < 0.4 ≈ contact latéral
var _push_cd: float = 0.0
# --- Fin : paramètres de poussée ---


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
	
	# Gestion du cooldown d’impulsions
	if _push_cd > 0.0:
		_push_cd -= delta
		
	#Conditions pour pousser : input latéral + (au sol si demandé)
	var dir := Input.get_axis("move_left", "move_right")
	var pushing_allowed := (dir != 0.0)
	if can_push_only_on_floor and not is_on_floor():
		pushing_allowed = false
		
	if pushing_allowed and _push_cd <= 0.0:
		var i := 0
		var slide_count := get_slide_collision_count()
		while i < slide_count:
			var col := get_slide_collision(i)
			var rb := col.get_collider()
			#On pousse seulement les objets "pushable"
			if rb is RigidBody2D and rb.is_in_group("pushable"):
				#Contact latéral (pas le sol/plafond)
				var side_contact = abs(col.get_normal().y) < push_side_angle
				# Le pad doit être DEVANT le joueur (évite de le "tirer" à travers soi)
				var delta_x = rb.global_position.x - global_position.x
				var front_ok := false
				if dir > 0.0 and delta_x > 0.0:
					front_ok = true
				elif dir < 0.0 and delta_x < 0.0:
					front_ok = true
				if side_contact and front_ok:
					var impulse := Vector2(dir * push_impulse, 0.0)
					rb.apply_central_impulse(impulse)
					_push_cd = push_cooldown
				# Optionnel : casser un peu ta vitesse pour éviter de "traverser"
				# velocity.x = move_toward(velocity.x, velocity.x, 0.0)  # no-op ici, garde si besoin
				break
			i += 1

	# Timers/états
	if boost_time > 0.0:
		boost_time = max(0.0, boost_time - delta)
	_was_on_floor = is_on_floor()
