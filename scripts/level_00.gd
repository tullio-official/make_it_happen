extends "res://scripts/level_base.gd"

func _ready():
	load_recipes()
	
	# Setup signal reception	
	Dialogic.text_signal.connect(_on_dialogic_text_signal)
	
	# Start dialogue
	Dialogic.start("res://dialogues/timelines/level_00_part_1.dtl")
	
	# Await computer to be at the top
	await godputer_placed_on_top
	
	# Resumes dialogue
	Dialogic.start("res://dialogues/timelines/level_00_part_2.dtl")
	
	# Await concept of tea to be mixed
	await concept_of_tea_mixed
	
	# Resumes dialogue
	Dialogic.start("res://dialogues/timelines/level_00_part_3.dtl")
