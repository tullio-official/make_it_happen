extends CanvasLayer

signal dialogue_started
signal dialogue_finished

@export var text_speed: float = 0.015
@export var short_pause: float = 0.2
@export var long_pause: float = 0.4

var dialogue_lines: Array[String] = []
var current_line_index: int = 0
var current_indent_level: int = 0

@onready var name_label: Label = $DialogueUI/NameLabel
@onready var dialogue_text: RichTextLabel = $DialogueUI/DialogueText
@onready var choice_container: VBoxContainer = $DialogueUI/ChoiceContainer

var choice_button_scene: PackedScene = preload("res://scenes/dialogue_choice_button.tscn")

var typewriter_timer: Timer
var is_paused: bool = false

var function_regex: RegEx = RegEx.new()
var inline_functions: Dictionary = {}

## Initializes the dialogue system, setting up the timer and regex parser.
func _ready() -> void:
	hide()
	setup_timer()
	# Compile the regex pattern to find strings formatted like [function_name(arg1, arg2)]
	function_regex.compile("\\[([a-zA-Z0-9_]+)\\((.*?)\\)\\]")

## Creates and configures the Timer node used for the typewriter text effect.
func setup_timer() -> void:
	typewriter_timer = Timer.new()
	add_child(typewriter_timer)
	typewriter_timer.timeout.connect(_on_typewriter_timeout)

## Listens for player input to advance or skip the dialogue.
func _input(event: InputEvent) -> void:
	# Ignore input if the UI is hidden or if the player is currently making a choice
	if not visible or choice_container.get_child_count() > 0:
		return
		
	var is_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_accept: bool = event.is_action_pressed("ui_accept")
	
	if is_click or is_accept:
		get_viewport().set_input_as_handled()
		handle_dialogue_advance()

## Determines whether to instantly reveal the rest of the typing text or proceed to the next line.
func handle_dialogue_advance() -> void:
	# If the text is still typing, force it to finish instantly
	if dialogue_text.visible_characters < dialogue_text.get_total_character_count():
		typewriter_timer.stop()
		is_paused = false
		
		# Ensure any inline functions that were skipped get triggered
		var skip_index: int = dialogue_text.visible_characters
		while skip_index <= dialogue_text.get_total_character_count():
			trigger_inline_functions(skip_index)
			skip_index += 1
			
		dialogue_text.visible_characters = dialogue_text.get_total_character_count()
	else:
		process_next_line()

## Opens a dialogue text file, reads it into memory, and begins playback.
func start_dialogue(file_path: String) -> void:
	dialogue_started.emit()
	dialogue_lines.clear()
	current_line_index = 0
	current_indent_level = 0
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to load dialogue file: ", file_path)
		return
		
	# Store the entire file content in the array for easier sequential parsing
	while not file.eof_reached():
		dialogue_lines.append(file.get_line())
		
	show()
	process_next_line()

## Parses the next valid line in the array, handling indent branches, choices, and standalone functions.
func process_next_line() -> void:
	while current_line_index < dialogue_lines.size():
		var raw_line: String = dialogue_lines[current_line_index]
		var line_indent: int = get_indent(raw_line)
		
		# Skip lines that belong to an unselected deeper branch
		if line_indent > current_indent_level:
			current_line_index += 1
			continue
			
		var clean_line: String = raw_line.strip_edges()
		
		if clean_line == "":
			close_dialogue_ui()
			return
			
		# If the indentation drops back down, update our tracker
		if line_indent < current_indent_level:
			current_indent_level = line_indent
			# If we drop down into a sibling choice block, skip over it
			if clean_line.begins_with("- "):
				skip_choice_block(line_indent)
				continue
				
		# Pause parsing to build UI buttons if a choice is encountered
		if clean_line.begins_with("- "):
			build_choices(current_line_index, current_indent_level)
			return
			
		# Execute standalone functions immediately without typing anything
		if clean_line.begins_with("[") and clean_line.ends_with("]") and not ": " in clean_line:
			extract_and_execute_standalone(clean_line)
			current_line_index += 1
			continue
			
		# Otherwise, parse the line as normal spoken dialogue
		parse_line(clean_line)
		current_line_index += 1
		return
		
	close_dialogue_ui()

## Calculates the indentation level of a given string based on tab characters.
func get_indent(line: String) -> int:
	var tab_count: int = 0
	for char in line:
		if char == "\t":
			tab_count += 1
		else:
			break
	return tab_count

## Dynamically generates UI buttons for a block of dialogue choices at the current indentation level.
func build_choices(start_index: int, target_indent: int) -> void:
	var check_index: int = start_index
	
	while check_index < dialogue_lines.size():
		var raw_line: String = dialogue_lines[check_index]
		var line_indent: int = get_indent(raw_line)
		var clean_line: String = raw_line.strip_edges()
		
		# Stop building choices if we hit an empty line or the indentation drops
		if clean_line == "" or line_indent < target_indent:
			break
			
		if line_indent == target_indent:
			if not clean_line.begins_with("- "):
				break
				
			var btn: Button = choice_button_scene.instantiate()
			btn.text = clean_line.substr(2)
			
			# Set up the visual indicator to only show when the mouse hovers
			var indicator: Node = btn.get_node("ButtonIndicator")
			indicator.hide()
			btn.mouse_entered.connect(indicator.show)
			btn.mouse_exited.connect(indicator.hide)
			
			choice_container.add_child(btn)
			btn.pressed.connect(_on_choice_pressed.bind(check_index + 1, target_indent + 1))
			
		check_index += 1

## Clears the choice UI and redirects the dialogue parser to the selected branch.
func _on_choice_pressed(target_index: int, new_indent: int) -> void:
	for child in choice_container.get_children():
		child.queue_free()
		
	current_line_index = target_index
	current_indent_level = new_indent
	process_next_line()

## Skips over unselected choice blocks to continue the main dialogue flow.
func skip_choice_block(target_indent: int) -> void:
	while current_line_index < dialogue_lines.size():
		var check_line: String = dialogue_lines[current_line_index]
		var check_indent: int = get_indent(check_line)
		var clean_check: String = check_line.strip_edges()
		
		if check_indent < target_indent:
			break
			
		if check_indent == target_indent and not clean_check.begins_with("- "):
			break
				
		current_line_index += 1

## Splits the dialogue line into a character name and spoken text, updating the UI accordingly.
func parse_line(line: String) -> void:
	var colon_index: int = line.find(": ")
	var text_to_parse: String = line
	
	# Separate the character name from their dialogue using the colon
	if colon_index != -1:
		name_label.text = line.substr(0, colon_index)
		name_label.show()
		text_to_parse = line.substr(colon_index + 2)
	else:
		name_label.hide()
		
	text_to_parse = extract_functions(text_to_parse)
	dialogue_text.text = text_to_parse
	start_typewriter()

## Scans text for inline function tags, stores them for execution, and returns a clean string.
func extract_functions(text: String) -> String:
	inline_functions.clear()
	var regex_match: RegExMatch = function_regex.search(text)
	
	while regex_match != null:
		var func_name: String = regex_match.get_string(1)
		var raw_args: String = regex_match.get_string(2)
		var args: Array = []
		
		# Parse and cast each argument so strict typing doesn't throw errors
		if raw_args != "":
			for arg in raw_args.split(","):
				var clean_arg: String = arg.strip_edges()
				
				if clean_arg.begins_with('"') and clean_arg.ends_with('"'):
					args.append(clean_arg.trim_prefix('"').trim_suffix('"'))
				elif clean_arg.is_valid_int():
					args.append(clean_arg.to_int())
				elif clean_arg.is_valid_float():
					args.append(clean_arg.to_float())
				elif clean_arg == "true":
					args.append(true)
				elif clean_arg == "false":
					args.append(false)
				else:
					args.append(clean_arg)
		
		var start_pos: int = regex_match.get_start()
		
		if not inline_functions.has(start_pos):
			inline_functions[start_pos] = []
			
		# Store the extracted function data to be triggered when the typewriter reaches this index
		inline_functions[start_pos].append({"name": func_name, "args": args})
		
		# Strip the function string out of the text so it doesn't display to the player
		text = text.substr(0, start_pos) + text.substr(regex_match.get_end())
		regex_match = function_regex.search(text)
		
	return text

## Processes and immediately executes a standalone function line.
func extract_and_execute_standalone(line: String) -> void:
	var regex_match: RegExMatch = function_regex.search(line)
	if regex_match != null:
		var func_name: String = regex_match.get_string(1)
		var raw_args: String = regex_match.get_string(2)
		var args: Array = []
		
		# Parse and cast each argument
		if raw_args != "":
			for arg in raw_args.split(","):
				var clean_arg: String = arg.strip_edges()
				
				if clean_arg.begins_with('"') and clean_arg.ends_with('"'):
					args.append(clean_arg.trim_prefix('"').trim_suffix('"'))
				elif clean_arg.is_valid_int():
					args.append(clean_arg.to_int())
				elif clean_arg.is_valid_float():
					args.append(clean_arg.to_float())
				elif clean_arg == "true":
					args.append(true)
				elif clean_arg == "false":
					args.append(false)
				else:
					args.append(clean_arg)
					
		execute_function(func_name, args)

## Fires any functions stored at the current typing index.
func trigger_inline_functions(index: int) -> void:
	if inline_functions.has(index):
		for func_data in inline_functions[index]:
			execute_function(func_data["name"], func_data["args"])

## Attempts to call a parsed function dynamically on the current level or itself.
func execute_function(func_name: String, args: Array) -> void:
	var current_level: Node = get_tree().current_scene
	
	# Try to execute on the active level first, fallback to this Autoload if not found
	if current_level != null and current_level.has_method(func_name):
		Callable(current_level, func_name).callv(args)
	elif has_method(func_name):
		Callable(self, func_name).callv(args)
	else:
		print("Function not found: ", func_name)

## Resets character visibility and initiates the recurring typewriter timer.
func start_typewriter() -> void:
	dialogue_text.visible_characters = 0
	is_paused = false
	typewriter_timer.start(text_speed)

## Increments visible characters and checks for pause conditions or line completion.
func _on_typewriter_timeout() -> void:
	if is_paused:
		return
		
	trigger_inline_functions(dialogue_text.visible_characters)
	dialogue_text.visible_characters += 1
	
	if dialogue_text.visible_characters >= dialogue_text.get_total_character_count():
		dialogue_text.visible_characters = dialogue_text.get_total_character_count()
		trigger_inline_functions(dialogue_text.visible_characters)
		typewriter_timer.stop()
		return
		
	check_punctuation_pause()

## Checks the current typed character to apply an auto-pause if it matches specific punctuation.
func check_punctuation_pause() -> void:
	var parsed_text: String = dialogue_text.get_parsed_text()
	var char_index: int = dialogue_text.visible_characters - 1
	var current_char: String = parsed_text[char_index]
	
	if current_char in [",", ":", ";"]:
		trigger_pause(short_pause)
	elif current_char in ["?", "!", "."]:
		trigger_pause(long_pause)

## Pauses the typewriter effect for a specified duration in seconds.
func trigger_pause(duration: float) -> void:
	is_paused = true
	typewriter_timer.stop()
	await get_tree().create_timer(duration).timeout
	is_paused = false
	
	if dialogue_text.visible_characters < dialogue_text.get_total_character_count():
		typewriter_timer.start(text_speed)

## Cleans up state variables, hides the UI, and signals that the dialogue has ended.
func close_dialogue_ui() -> void:
	hide()
	typewriter_timer.stop()
	dialogue_lines.clear()
	current_line_index = 0
	current_indent_level = 0
	
	for child in choice_container.get_children():
		child.queue_free()
		
	dialogue_finished.emit()
	print("Dialogue UI closed.")
