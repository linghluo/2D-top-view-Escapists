extends CharacterBody2D

@export var speed: float = 8000.0 # 角色速度
@export var alertness_upspeed: float = 1.0 # 警觉值增长速度
@export var alertness_downspeed: float = 1.0 # 警戒值减少速度
var alertness: float = 0 # 初始化警觉值

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

# 警觉值增加方法
func alert_up():
	alertness += alertness_upspeed

# 警戒值减少方法
func alert_down():
	alertness -= alertness_downspeed
