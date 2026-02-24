extends PanelContainer

var grid_pos : Vector2i
var grid_data_ref : Dictionary

func _get_drag_data(at_position: Vector2) -> Variant:
	var item_info = grid_data_ref[grid_pos]
	
	# Abort if cell empty
	if item_info == null:
		return null
		
	# Package data for drop
	var payload = {
		"start_pos": grid_pos,
		"item_name": item_info[0],
		"item_path": item_info[1],
		"texture": $TextureRect.texture
	}
	
	# Create drag visual preview
	var preview = TextureRect.new()
	preview.texture = payload["texture"]
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(150, 150)
	
	# Center preview on cursor
	preview.position = Vector2(-60, -60)
	
	# Anchor preview to cursor
	var preview_anchor = Control.new()
	preview_anchor.add_child(preview)
	set_drag_preview(preview_anchor)
	
	return payload

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Validate incoming drop data
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("start_pos") and data.has("item_name"):
			return true
			
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Ignore drop on self
	if grid_pos == data["start_pos"]:
		return

	# Find origin cell node
	var origin_cell_name = "Cell%dX%dY" % [data["start_pos"].x, data["start_pos"].y]
	var origin_cell = get_parent().get_node(origin_cell_name)

	# Update visual textures
	$TextureRect.texture = data["texture"]
	origin_cell.get_node("TextureRect").texture = null

	# Update backend grid data
	grid_data_ref[grid_pos] = [data["item_name"], data["item_path"]]
	grid_data_ref[data["start_pos"]] = null
