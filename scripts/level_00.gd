extends "res://scripts/level_base.gd"

func _ready():
	Dialogic.text_signal.connect(_on_dialogic_text_signal)
	Dialogic.start("res://dialogues/timelines/main_timeline.dtl")

func _on_dialogic_text_signal(argument: String):
	if argument == "generate_grid":
		generate_grid()
	if argument == "spawn_godputer":
		place_item("res://assets/godputer.svg", 2, 2)
