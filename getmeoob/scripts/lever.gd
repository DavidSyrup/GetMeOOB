# Lever.gd
extends Node2D

@export var action_name: StringName = "interact"
@export var player_group: StringName = "player"
@export var target_pad: NodePath        # assigne ton pad dans l’inspector
@export var affect_group: StringName = "" # option: si tu veux affecter plusieurs pads par groupe
@export var lever_on: bool = false

@onready var zone: Area2D = $InteractZone
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
var _player_in_range: Node = null
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_in_range = body

func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null

func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed(action_name):
		_toggle_pads()
		if lever_on == true:
			animatedSprite.play("OFF")
			lever_on = false
		else:
			animatedSprite.play("ON")
			lever_on = true
		

func _toggle_pads() -> void:
	var targets: Array = []

	if target_pad != NodePath():
		var t := get_node_or_null(target_pad)
		if t: targets.append(t)
	elif affect_group != "":
		targets = get_tree().get_nodes_in_group(affect_group)

	for t in targets:
		# On essaie des API "douces" selon ce que ton pad expose :
		if t.has_method("toggle_direction"):
			t.toggle_direction()
		elif "face_left" in t:
			t.face_left = not t.face_left
			if t.has_node("Visual/AnimatedSprite2D"):
				(t.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D).flip_h = t.face_left
		elif "invert_direction" in t:
			t.invert_direction = not t.invert_direction
		elif "boost_vector" in t:
			t.boost_vector = -t.boost_vector
