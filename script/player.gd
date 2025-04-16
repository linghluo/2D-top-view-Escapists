extends CharacterBody2D

@export var speed := 8000.0

func _physics_process(delta):
	# 角色移动
	var dir = Vector2(
		Input.get_action_strength("p_right") - Input.get_action_strength("p_left"),
		Input.get_action_strength("p_down") - Input.get_action_strength("p_up")
	).normalized()
	velocity = dir * speed * delta
	move_and_slide()

	# 角色朝向鼠标位置
	look_at(get_global_mouse_position())
