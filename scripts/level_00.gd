extends "res://scripts/level_base.gd"

func _ready() -> void:
	super._ready()
	
	var godputer = ColorRect.new()
	godputer.custom_minimum_size = Vector2(calculated_cell_size, calculated_cell_size)
	godputer.color = Color("#C0C0C0") 
	place_item_in_grid(godputer, 1, 0)
	godputer.position -= Vector2(calculated_cell_size / 2.0, calculated_cell_size / 2.0)
	
	var hot_water = ColorRect.new()
	hot_water.custom_minimum_size = Vector2(calculated_cell_size, calculated_cell_size)
	hot_water.color = Color("#0000FF") 
	place_item_in_grid(hot_water, 0, 1)
	hot_water.position -= Vector2(calculated_cell_size / 2.0, calculated_cell_size / 2.0)
	
	var teabag = ColorRect.new()
	teabag.custom_minimum_size = Vector2(calculated_cell_size, calculated_cell_size)
	teabag.color = Color("#8B4513") 
	place_item_in_grid(teabag, 2, 1)
	teabag.position -= Vector2(calculated_cell_size / 2.0, calculated_cell_size / 2.0)
