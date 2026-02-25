extends "res://scripts/level_base.gd"

func _ready():
	# Setup signal reception	
	Dialogic.text_signal.connect(_on_dialogic_text_signal)
	
	# Start dialogue
	Dialogic.start("res://dialogues/timelines/level_00_part_1.dtl")
	
	# Await computer to be at the top
	await is_godputer_top
	
	# Resumes dialogue
	Dialogic.start("res://dialogues/timelines/level_00_part_2.dtl")
