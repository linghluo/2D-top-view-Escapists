extends Control

@onready var label = $ColorRect/Label
@onready var color_rect = $ColorRect

var story_lines: Array[String] = []
var current_index := 0
var active := false
var is_typing := false
var full_text := ""
var char_index := 0

var printing_speed := 0.06 # 打字速度

func _ready():
	visible = false
	if not has_node("TypingTimer"):
		var typing_timer = Timer.new()
		typing_timer.name = "TypingTimer"
		typing_timer.one_shot = true
		add_child(typing_timer)

func show_story(lines: Array):
	story_lines = lines
	current_index = 0
	active = true
	visible = true
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.4)

	display_current_line()

func display_current_line():
	if current_index >= story_lines.size():
		hide_story()
		return

	full_text = story_lines[current_index]
	char_index = 0
	label.text = ""
	is_typing = true
	type_next_char()

func type_next_char():
	if char_index < full_text.length():
		label.text += full_text[char_index]
		char_index += 1
		var timer = $TypingTimer
		timer.wait_time = printing_speed
		timer.start()
		timer.timeout.connect(type_next_char, CONNECT_ONE_SHOT)
	else:
		is_typing = false

func hide_story():
	active = false
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(hide)

func _unhandled_input(event):
	if active and event.is_action_pressed("row_next"):
		if is_typing:
			return
		current_index += 1
		display_current_line()
