extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@onready var animated_sprite = $AnimatedSprite2D
var last_movement = "left"

func _physics_process(delta: float) -> void:
	
	var dive = 0
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if is_on_floor():
		dive = 0
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("move_down") and !is_on_floor():
		velocity.y = -JUMP_VELOCITY
		dive = 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		animated_sprite.play("Run_Right")
		last_movement = "right";
	elif direction < 0:
		animated_sprite.play("Run_Left")
		last_movement = "left";
		
	if direction == 0 && last_movement == "left":
		animated_sprite.play("Idle_Left")
	elif direction == 0 && last_movement == "right":
		animated_sprite.play("Idle_Right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
