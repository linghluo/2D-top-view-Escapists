extends Area2D

@export var story_lines: Array[String] = []

@export var only_trigger_once := false

var triggered = false

func _ready():
    connect("body_entered", _on_body_entered)
    connect("body_exited", _on_body_exited)

func _on_body_entered(body):
    if body.name == "player" and not triggered:
        triggered = true
        var ui = get_tree().get_root().get_node("Main/CanvasLayer/storyUI")
        if ui:
            ui.show_story(story_lines)

func _on_body_exited(body):
    if body.name == "player":
        var ui = get_tree().get_root().get_node("Main/CanvasLayer/storyUI")
        if ui:
            ui.hide_story()
        triggered = false