extends Node2D

@export var grid_cols : int = 2
@export var grid_rows : int = 2
@export var cell_size : float = 0.10
@export var cell_spacing : float = 0.015
@export var sprite_ratio : float = 0.80
@export var sprite_native_size : float = 256.0

var grid_data : Dictionary = {}
var calculated_cell_size : float = 0.0

func _ready() -> void:
	generate_grid()

func generate_grid() -> void:
	grid_data.clear()
	
	var screen_size : Vector2 = get_viewport_rect().size
	calculated_cell_size = screen_size.y * cell_size
	var calculated_cell_spacing : float = screen_size.y * cell_spacing
	
	var total_width : float = (grid_cols * calculated_cell_size) + ((grid_cols - 1) * calculated_cell_spacing)
	var total_height : float = (grid_rows * calculated_cell_size) + ((grid_rows - 1) * calculated_cell_spacing)
	
	var start_x : float = (screen_size.x - total_width) / 2.0
	var start_y : float = (screen_size.y - total_height) / 2.0
	
	for y in range(grid_rows):
		for x in range(grid_cols):
			var pos_x : float = start_x + (x * (calculated_cell_size + calculated_cell_spacing))
			var pos_y : float = start_y + (y * (calculated_cell_size + calculated_cell_spacing))
			var pixel_position : Vector2 = Vector2(pos_x, pos_y)
			
			var cell_visual := ColorRect.new()
			cell_visual.size = Vector2(calculated_cell_size, calculated_cell_size)
			cell_visual.position = pixel_position
			cell_visual.color = Color("#4A4A4A")
			add_child(cell_visual)
			
			grid_data[Vector2(x, y)] = {
				"pixel_position": pixel_position,
				"item": null
			}

func place_item(item_node, grid_x: int, grid_y: int) -> void:
	var target_coord := Vector2(grid_x, grid_y)
	
	if not grid_data.has(target_coord):
		push_warning("Attempted to place item out of grid bounds.")
		return
		
	if grid_data[target_coord]["item"] != null:
		push_warning("Target cell is already occupied.")
		return
		
	var cell_top_left : Vector2 = grid_data[target_coord]["pixel_position"]
	var center_offset := Vector2(calculated_cell_size / 2.0, calculated_cell_size / 2.0)
	
	item_node.position = cell_top_left + center_offset
	
	var target_size : float = calculated_cell_size * sprite_ratio
	var scale_factor : float = target_size / sprite_native_size
	item_node.scale = Vector2(scale_factor, scale_factor)
	
	add_child(item_node)
	
	grid_data[target_coord]["item"] = item_node
