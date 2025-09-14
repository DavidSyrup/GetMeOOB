extends Area2D

@export var speed_threshold: float = 200.0
@onready var solid_collision: CollisionShape2D = $"../StaticBody2D/CollisionShape2D"
@onready var mask_tilemap: TileMapLayer = get_node("../../Masklayer")

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		var speed = abs(body.velocity.x)
		if speed >= speed_threshold:
			solid_collision.call_deferred("set_disabled", true)
			print("Mur ok :", body.name)
			reveal_mask()
		else:
			solid_collision.call_deferred("set_disabled", false)
			print("Mur ko :", body.name)

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		solid_collision.call_deferred("set_disabled", false)
		print("le joueur est passé", body.name)
		

func reveal_mask():
	for cell in mask_tilemap.get_used_cells():
		mask_tilemap.erase_cell(cell)
