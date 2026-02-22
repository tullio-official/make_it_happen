extends "res://scripts/level_base.gd"

func _ready() -> void:
	var dialogue_resource = load("res://dialogues/level_00_dialogue.dialogue")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

func _on_dialogue_ended(resource: DialogueResource) -> void:
	pass
