extends Control

signal is_godputer_top(tf: bool)

# Set up grid variables
@export var grid_cols := 3
@export var grid_rows := 3
@export var cell_size := 180
@export var cell_spacing := 27
@export var cell_padding := 30

# Store grid state data
var grid_data : Dictionary = {}

func _ready() -> void:
	generate_grid()
	place_item("godputer", 2, 1)
	print(grid_data)

## Generates an empty X×Y grid and initiates grid_data.
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
			
			# Connect the cell's signal to a function in this script
			cell_instance.item_dropped.connect(_on_cell_item_dropped)
			
			# Add cell to grid
			grid.add_child(cell_instance)
			
			# Create empty dictionary entry
			grid_data[Vector2i(x + 1, y + 1)] = null

## Runs everytime an item is moved
func _on_cell_item_dropped(pos: Vector2i, item_name: String):
	if item_name == "godputer" and pos.y == 1:
		is_godputer_top.emit(true)

## Places a texture in a cell and updates grid_data.
func place_item(item:String, x:int, y:int) -> void:
	# Find target cell node
	var cell = get_node_or_null("CenterContainer/GridContainer/Cell%dX%dY" % [x, y])
	if not cell: return
	
	# Get cell texture node
	var tr = cell.get_node("TextureRect")

	# Load and resize image
	var path = "res://assets/" + item + ".svg"
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
	grid_data[Vector2i(x, y)] = [item, path]

## Runs string signals as functions. Separate function and arguments with colons ":".
func _on_dialogic_text_signal(argument_string: String):
	var parts = Array(argument_string.split(":"))
	var action_name = parts.pop_front()
	
	var typed_args = []
	
	for arg in parts:
		if arg.is_valid_int():
			typed_args.append(arg.to_int())
		elif arg.is_valid_float():
			typed_args.append(arg.to_float())
		elif arg.to_lower() == "true":
			typed_args.append(true)
		elif arg.to_lower() == "false":
			typed_args.append(false)
		else:
			typed_args.append(arg)
			
	var dynamic_callable = Callable(self, action_name)
	
	if dynamic_callable.is_valid():
		dynamic_callable.callv(typed_args)
