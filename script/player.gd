extends CharacterBody2D

@export var speed := 200.0

func _physics_process(_delta):
	var input_vector = Vector2(
		Input.get_action_strength("p_right") - Input.get_action_strength("p_left"),
		Input.get_action_strength("p_down") - Input.get_action_strength("p_up")
	).normalized()

	velocity = input_vector * speed
	move_and_slide()
