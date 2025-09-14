extends Node2D
@onready var mask_tilemap: TileMapLayer = get_node("../Masklayer")


func _on_area_2d_body_entered(body) -> void:
	reveal_mask()
	
	
func reveal_mask():
	for cell in mask_tilemap.get_used_cells():
		mask_tilemap.erase_cell(cell)
