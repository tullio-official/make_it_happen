extends Control

signal godputer_placed_on_top(is_top: bool)

const CELL_SCENE: PackedScene = preload("res://scenes/cell.tscn")

# --- Grid Configuration ---
@export var grid_columns: int = 3
@export var grid_rows: int = 3
@export var cell_size: int = 180
@export var cell_spacing: int = 27
@export var cell_padding: int = 30

@onready var grid_container: GridContainer = $CenterContainer/GridContainer

## Stores the state of the grid. Keys are Vector2i positions, values are item dictionaries.
var grid_data: Dictionary = {}
## Stores the list of valid recipes loaded from JSON.
var recipe_db: Array = []

func _ready() -> void:
	load_recipes()
	generate_grid()
	place_item("matter", 1, 1)
	place_item("matter", 1, 2)

## Generates an empty X by Y grid based on the export variables and initializes grid_data.
func generate_grid() -> void:
	grid_container.columns = grid_columns
	
	# Apply spacing between cells
	grid_container.add_theme_constant_override("h_separation", cell_spacing)
	grid_container.add_theme_constant_override("v_separation", cell_spacing)

	# Loop through rows (y) and columns (x) to create cells
	for y: int in range(grid_rows):
		for x: int in range(grid_columns):
			# Calculate grid coordinates starting from 1 (e.g., 1x1, 1x2)
			var current_pos := Vector2i(x + 1, y + 1)
			
			var cell_instance: Control = CELL_SCENE.instantiate()
			cell_instance.name = "Cell%dX%dY" % [current_pos.x, current_pos.y]
			cell_instance.custom_minimum_size = Vector2(cell_size, cell_size)
			
			# Pass necessary data and references to the cell instance
			cell_instance.grid_pos = current_pos
			cell_instance.grid_data_ref = grid_data
			cell_instance.level_ref = self
			
			# Listen for when an item is dropped onto this specific cell
			cell_instance.item_dropped.connect(_on_cell_item_dropped)
			
			grid_container.add_child(cell_instance)
			
			# Initialize the grid data at this position as null
			grid_data[current_pos] = null

## Triggered when the `item_dropped` signal is emitted from any cell.
func _on_cell_item_dropped(pos: Vector2i, item_name: String) -> void:
	# Check if godputer was placed in the top row
	if item_name == "godputer" and pos.y == 1:
		godputer_placed_on_top.emit(true)

## Visually places an item in a specific cell and updates the grid_data dictionary.
func place_item(item_name: String, x: int, y: int) -> void:
	# Find the specific cell node based on its naming convention
	var cell_path := "CenterContainer/GridContainer/Cell%dX%dY" % [x, y]
	var cell: Control = get_node_or_null(cell_path)
	
	# Stop execution if the cell doesn't exist
	if not cell:
		return
		
	var texture_rect: TextureRect = cell.get_node("TextureRect")
	var file_path := "res://assets/%s.svg" % item_name
	
	# Configure the texture to fit nicely within the cell
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = load(file_path)
	
	# Apply padding so the image doesn't touch the edges of the cell
	var padding_vector := Vector2(cell_padding, cell_padding)
	texture_rect.custom_minimum_size = Vector2(cell_size, cell_size) - padding_vector
	
	# Save the item's data to the grid state tracker
	grid_data[Vector2i(x, y)] = {
		"name": item_name,
		"path": file_path
	}

## Parses a string signal from Dialogic and calls the corresponding function.
## Signal format should be "function_name\:arg1\:arg2\:arg3\:arg4...".
func _on_dialogic_text_signal(argument_string: String) -> void:
	# Split the string into an array using the colon separator
	var parts := argument_string.split(":")
	var action_name := parts[0]
	
	# Remove the function name so only arguments remain
	parts.remove_at(0)
	
	var typed_args: Array = []
	
	# Convert string arguments into their proper data types
	for arg: String in parts:
		if arg.is_valid_int():
			typed_args.append(arg.to_int())
		elif arg.is_valid_float():
			typed_args.append(arg.to_float())
		elif arg.to_lower() == "true":
			typed_args.append(true)
		elif arg.to_lower() == "false":
			typed_args.append(false)
		else:
			# Leave as a string if it doesn't match numbers or booleans
			typed_args.append(arg)
	
	# Create a dynamic reference to the function on this script
	var dynamic_callable := Callable(self, action_name)
	
	# Execute the function with the converted arguments if it exists
	if dynamic_callable.is_valid():
		dynamic_callable.callv(typed_args)

## Reads the recipes.json file and stores its contents in the recipe_db array.
func load_recipes() -> void:
	var file_path := "res://data/recipes.json"
	var file := FileAccess.open(file_path, FileAccess.READ)
	
	if file:
		var json_text := file.get_as_text()
		file.close()
		
		# Parse the JSON string into Godot data types (Array/Dictionary)
		var parsed_data: Variant = JSON.parse_string(json_text)
		
		# Ensure the parsed data is an Array before assigning it
		if typeof(parsed_data) == TYPE_ARRAY:
			recipe_db = parsed_data

## Compares two items against the loaded recipe DB to see if they combine.
## Returns an array of output items if a match is found, or an empty array if not.
func check_combination(item1: String, item2: String) -> Array:
	for recipe: Dictionary in recipe_db:
		var inputs: Array = recipe.get("inputs", [])
		
		# Check if both items are required by a recipe
		if item1 in inputs and item2 in inputs:
			
			# If combining two of the same item, ensure the recipe actually requires two
			if item1 == item2 and inputs.count(item1) < 2:
				continue
			return recipe.get("outputs", [])
	
	# Return an empty array if no matching recipe is found
	return []
