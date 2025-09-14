extends Node2D
@onready var mask_tilemap: TileMapLayer = get_node("../Masklayer")
@onready var collision_shape := get_node("StaticBody2D/CollisionShape2D")
@export var speed_threshold: float = 100.0


	
func _on_body_entered(body: Node) -> void:
	print("coucou")
	if body.name == "Player":
		var speed = abs(body.velocity.x)
		if speed >= speed_threshold:
			collision_shape.call_deferred("set_disabled", true)
			reveal_mask()
			print("Mur traversable")
		else:
			collision_shape.call_deferred("set_disabled", false)
			print("Mur solide")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		# put back wall
		collision_shape.call_deferred("set_disabled", false)
		
func reveal_mask():
	for cell in mask_tilemap.get_used_cells():
		mask_tilemap.erase_cell(cell)
