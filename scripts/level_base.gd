extends Node2D

@export var grid_cols : int = 2
@export var grid_rows : int = 2
@export var cell_size_percent : float = 0.10
@export var cell_spacing_percent : float = 0.015

@onready var grid_container : GridContainer = $GridContainer
@onready var screen_size : Vector2 = get_viewport_rect().size

var calculated_cell_size : float = 0.0
var calculated_cell_spacing : float = 0.0
var total_width : float = 0.0
var total_height : float = 0.0

var grid_data : Dictionary = {}

func _ready() -> void:
	generate_grid()

func generate_grid() -> void:
	# Calculate effective cell size based on VP height
	calculated_cell_size = screen_size.y * cell_size_percent
	calculated_cell_spacing = screen_size.y * cell_spacing_percent

	# Define GridContainer stuff
	grid_container.columns = grid_cols
	grid_container.add_theme_constant_override("h_separation", int(calculated_cell_spacing))
	grid_container.add_theme_constant_override("v_separation", int(calculated_cell_spacing))

	# Calculate total size of the grid
	total_width = (grid_cols * calculated_cell_size) + ((grid_cols - 1) * calculated_cell_spacing)
	total_height = (grid_rows * calculated_cell_size) + ((grid_rows - 1) * calculated_cell_spacing)

	# Find grid anchor point
	grid_container.position = Vector2(
		(screen_size.x - total_width) / 2.0,
		(screen_size.y - total_height) / 2.0
	)
	
	# Populate the grid
	for i in range(grid_rows*grid_cols):
		var cell = ColorRect.new()
		cell.custom_minimum_size = Vector2(calculated_cell_size, calculated_cell_size)
		cell.color = Color("#4A4A4A")
		grid_container.add_child(cell)

func place_item_in_grid(item_node: Node, grid_x: int, grid_y: int) -> void:
	# ERROR Out of bounds
	if grid_x < 0 or grid_x >= grid_cols or grid_y < 0 or grid_y >= grid_rows:
		push_error("Grid coordinates out of bounds.")
		return

	# Store cell coordinates
	var cell_coord = Vector2i(grid_x, grid_y)
	
	# ERROR Cell occupied
	if grid_data.has(cell_coord):
		push_error("Cell is already occupied.")
		return

	# Fill cell
	var cell_index = (grid_y * grid_cols) + grid_x
	var target_cell = grid_container.get_child(cell_index)

	target_cell.add_child(item_node)
	
	if "position" in item_node:
		item_node.position = Vector2(calculated_cell_size / 2.0, calculated_cell_size / 2.0)

	grid_data[cell_coord] = item_node
