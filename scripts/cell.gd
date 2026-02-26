extends PanelContainer

signal item_dropped(position: Vector2i, item_name: String)
signal successful_mix(outputs: Array)

var grid_pos: Vector2i
var grid_data_ref: Dictionary
var level_ref: Control

func _get_drag_data(at_position: Vector2) -> Variant:
	var item_info: Variant = grid_data_ref.get(grid_pos)
	
	if item_info == null:
		return null
		
	var payload: Dictionary = {
		"start_pos": grid_pos,
		"item_name": item_info["name"],
		"item_path": item_info["path"],
		"texture": $TextureRect.texture
	}
	
	var preview := TextureRect.new()
	preview.texture = payload["texture"]
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(150, 150)
	
	preview.position = Vector2(-60, -60)
	
	var preview_anchor := Control.new()
	preview_anchor.add_child(preview)
	set_drag_preview(preview_anchor)
	
	return payload

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("start_pos") and data.has("item_name"):
			return true
			
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if grid_pos == data["start_pos"]:
		return

	var origin_cell_name := "Cell%dX%dY" % [data["start_pos"].x, data["start_pos"].y]
	var origin_cell: Control = get_parent().get_node(origin_cell_name)
	
	var target_item_info: Variant = grid_data_ref.get(grid_pos)

	if target_item_info == null:
		$TextureRect.texture = data["texture"]
		origin_cell.get_node("TextureRect").texture = null

		grid_data_ref[grid_pos] = {
			"name": data["item_name"],
			"path": data["item_path"]
		}
		grid_data_ref[data["start_pos"]] = null
		
		item_dropped.emit(grid_pos, data["item_name"])
	else:
		var dragged_item: String = data["item_name"]
		var target_item: String = target_item_info["name"]
		var outputs: Array = level_ref.check_combination(dragged_item, target_item)
		
		if outputs.size() > 0:
			origin_cell.get_node("TextureRect").texture = null
			grid_data_ref[data["start_pos"]] = null
			
			level_ref.place_item(outputs[0], grid_pos.x, grid_pos.y)
			
			if outputs.size() > 1:
				level_ref.place_item(outputs[1], data["start_pos"].x, data["start_pos"].y)
				
			item_dropped.emit(grid_pos, outputs[0])
			successful_mix.emit(outputs)
			print(outputs)
		else:
			return
