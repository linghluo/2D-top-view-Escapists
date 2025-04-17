extends CharacterBody2D

@export var speed: float = 8000.0 # 角色速度
@export var alertness_downspeed: float = 2.0 # 警觉值下降速度
var can_downalert: bool = true # 是否可以降低警戒

var time_can_downalert: float = 0 # 记录重置可以下降警戒的时间
var time_can_downalert_speed: float = 20.0 # 重置警戒时间的速度参数，单位为秒
var alertness: float = 0 # 初始化警觉值

func _ready() -> void:
	# 警戒值重置计时器
	$Timer_reset_alertness.wait_time = 20.0
	$Timer_reset_alertness.start()

func _physics_process(delta):
	# 角色移动
	var dir1 = Vector2(
		Input.get_action_strength("p_right") - Input.get_action_strength("p_left"),
		Input.get_action_strength("p_down") - Input.get_action_strength("p_up")
	).normalized()
	velocity = dir1 * speed * delta
	move_and_slide()

	# 角色朝向鼠标位置
	var mouse_pos = get_global_mouse_position()
	var dir2 = (mouse_pos - global_position).angle()
	var pos_to = abs(angle_difference(rotation, dir2))
	if pos_to > 0.1:
		rotation = lerp_angle(rotation, dir2, 7 * delta)

	# 警戒值自然下降
	if can_downalert and alertness > 0:
		alert_down(delta)

# 警戒重置计时器函数体
func _on_timer_timeout() -> void:
	can_downalert = true
	print("重置警戒")

# 警戒值减少方法
func alert_down(delta: float):
	alertness -= alertness_downspeed * delta
	if alertness < 0:
		alertness = 0
