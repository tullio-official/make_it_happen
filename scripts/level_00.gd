extends "res://scripts/level_base.gd"

func _ready():
	load_recipes()
	DialogueSystem.start_dialogue("res://dialogues/timelines/level_00_part_1.txt")
	await godputer_placed_on_top
	DialogueSystem.start_dialogue("res://dialogues/timelines/level_00_part_2.txt")
	await concept_of_tea_mixed
	DialogueSystem.start_dialogue("res://dialogues/timelines/level_00_part_3.txt")
