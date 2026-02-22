extends Node2D

@export var grid_cols : int = 5
@export var grid_rows : int = 5
@export var cell_size_percent : float = 0.10
@export var cell_spacing_percent : float = 0.015

@onready var grid_container = $GridContainer

var grid_start_x : float = 0.0
var grid_start_y : float = 0.0
var calculated_cell_size : float = 0.0
var calculated_cell_spacing : float = 0.0

var grid_data : Dictionary = {}

func _ready() -> void:
	generate_grid(3, 2)

func generate_grid(grid_cols: int, grid_rows: int) -> void:
	var screen_size = get_viewport_rect().size
	
	calculated_cell_size = screen_size.y * cell_size_percent
	calculated_cell_spacing = screen_size.y * cell_spacing_percent
	
	var total_width = (grid_cols * calculated_cell_size) + ((grid_cols - 1) * calculated_cell_spacing)
	var total_height = (grid_rows * calculated_cell_size) + ((grid_rows - 1) * calculated_cell_spacing)
	
	grid_start_x = (screen_size.x - total_width) / 2.0
	grid_start_y = (screen_size.y - total_height) / 2.0
	
	for y in range(grid_rows):
		for x in range(grid_cols):
			var cell = ColorRect.new()
			cell.custom_minimum_size = Vector2(calculated_cell_size, calculated_cell_size)
			cell.color = Color("#4A4A4A")
			
			var pos_x = grid_start_x + (x * (calculated_cell_size + calculated_cell_spacing))
			var pos_y = grid_start_y + (y * (calculated_cell_size + calculated_cell_spacing))
			cell.position = Vector2(pos_x, pos_y)
			
			grid_container.add_child(cell)

func get_cell_position(grid_x: int, grid_y: int) -> Vector2:
	var pos_x = grid_start_x + (grid_x * (calculated_cell_size + calculated_cell_spacing))
	var pos_y = grid_start_y + (grid_y * (calculated_cell_size + calculated_cell_spacing))
	
	pos_x += calculated_cell_size / 2.0
	pos_y += calculated_cell_size / 2.0
	
	return Vector2(pos_x, pos_y)

func place_item_in_grid(item_node, grid_x: int, grid_y: int) -> void:
	if grid_x < 0 or grid_x >= grid_cols or grid_y < 0 or grid_y >= grid_rows:
		push_error("Grid coordinates out of bounds.")
		return
		
	var cell_coord = Vector2(grid_x, grid_y)
	
	if grid_data.has(cell_coord):
		push_error("Cell is already occupied.")
		return
		
	grid_container.add_child(item_node)
	item_node.position = get_cell_position(grid_x, grid_y)
	grid_data[cell_coord] = item_node
