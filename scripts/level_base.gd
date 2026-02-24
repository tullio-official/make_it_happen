extends Control

# Set up grid variables
@export var grid_cols := 3
@export var grid_rows := 3
@export var cell_size := 180
@export var cell_spacing := 27
@export var cell_padding := 30

# Store grid state data
var grid_data : Dictionary = {}

func _ready() -> void:
	# Build grid on start
	generate_grid()
	place_item("res://assets/godputer.svg", 2, 1)
	print(grid_data)

func generate_grid() -> void:
	# Get grid container node
	var grid = $CenterContainer/GridContainer
	var cell_scene = preload("res://scenes/cell.tscn")

	# Apply grid layout settings
	grid.columns = grid_cols
	grid.add_theme_constant_override("h_separation", cell_spacing)
	grid.add_theme_constant_override("v_separation", cell_spacing)

	# Loop through rows, columns
	for y in range(grid_rows):
		for x in range(grid_cols):
			# Spawn new cell instance
			var cell_instance = cell_scene.instantiate()
			cell_instance.name = "Cell%dX%dY" % [x + 1, y + 1]
			cell_instance.custom_minimum_size = Vector2(cell_size, cell_size)
			
			# Assign cell grid data
			cell_instance.grid_pos = Vector2i(x + 1, y + 1)
			cell_instance.grid_data_ref = grid_data
			
			# Add cell to grid
			grid.add_child(cell_instance)
			
			# Create empty dictionary entry
			grid_data[Vector2i(x + 1, y + 1)] = null

func place_item(path:String, x:int, y:int) -> void:
	# Find target cell node
	var cell = get_node_or_null("CenterContainer/GridContainer/Cell%dX%dY" % [x, y])
	if not cell: return
	
	# Get cell texture node
	var tr = cell.get_node("TextureRect")

	# Load and resize image
	var tex = load(path)
	var image = tex.get_image()
	var target_size = cell_size - cell_padding
	image.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)

	# Create the final texture
	tex = ImageTexture.create_from_image(image)

	# Apply texture to cell
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tr.texture = tex
	
	# Save item to data
	var item = path.get_file().get_basename()
	grid_data[Vector2i(x, y)] = [item, path]
