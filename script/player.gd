extends CharacterBody2D

@export var normal_speed: float = 80.0 # 正常行走速度
@export var sneak_speed: float = 40.0 # 潜行行走速度
@export var dash_speed: float = 1000.0 # 冲刺速度（像素/秒）
@export var dash_distance: float = 150.0 # 冲刺固定距离（像素）
@export var dash_charge_time: float = 1.0 # 蓄力时长（秒）
@export var dash_cooldown: float = 2.0 # 冲刺冷却（秒）
@export var ghost_interval: float = 0.02 # 残影生成间隔（秒）
@onready var charge_particles: CPUParticles2D = $CPUParticles_dash

# 冲刺系统相关
var dash_charge_timer: float = 0.0 # 蓄力倒计时
var dash_timer: float = 0.0 # 冲刺冷却倒计时
var dash_direction: Vector2 = Vector2.ZERO # 冲刺方向
var dash_start_pos: Vector2 = Vector2.ZERO # 冲刺起点
var dash_end_pos: Vector2 = Vector2.ZERO # 冲刺终点
var ghost_timer: float = 0.0 # 残影生成倒计时

# 警觉值相关系统
var can_downalert: bool = true # 是否允许警觉值下降
@export var alertness_downspeed: float = 2.0 # 警觉值下降速率 (/秒)
@export var time_can_downalert_speed: float = 20.0 # 重置可降警戒tag时间
var alertness: float = 0.0 # 警觉值

# 玩家状态机
enum State {normal, sneak, dash_change, dash}
var state: State = State.normal # 初始化状态机

func _ready() -> void:
	# 警觉值重置定时器
	$Timer_reset_alertness.wait_time = time_can_downalert_speed
	$Timer_reset_alertness.start()

func _on_timer_reset_alertness_timeout() -> void:
	can_downalert = true

func _physics_process(delta: float) -> void:
	print("alertness: ", alertness)
	# 清空速度（更好的速度管理）
	velocity = Vector2.ZERO

	# 状态机
	match state:
		State.normal:
			var dir = get_input_dir()
			velocity = dir * normal_speed
			if Input.is_action_pressed("p_sneak"):
				state = State.sneak
			elif Input.is_action_just_pressed("p_dash") and dash_timer <= 0.0:
				state = State.dash_change
				dash_charge_timer = dash_charge_time
				charge_particles.emitting = true

		State.sneak:
			var dir2 = get_input_dir()
			velocity = dir2 * sneak_speed
			if Input.is_action_just_released("p_sneak"):
				state = State.normal

		State.dash_change:
			dash_charge_timer -= delta
			if Input.is_action_just_released("p_dash"):
				charge_particles.emitting = false
				if dash_charge_timer <= 0.0:
					# 蓄力完成，记录起点与终点，进入冲刺状态
					dash_direction = (get_global_mouse_position() - global_position).normalized()
					dash_start_pos = global_position
					dash_end_pos = dash_start_pos + dash_direction * dash_distance
					state = State.dash
					dash_timer = dash_cooldown
					ghost_timer = 0.0
				else:
					# 蓄力失败，回归初始
					state = State.normal

		State.dash:
			# 冲刺用的临时速度
			velocity = dash_direction * dash_speed
			# 冲刺位移限制
			if global_position.distance_to(dash_start_pos) >= dash_distance:
				state = State.normal
				velocity = Vector2.ZERO
			# 残影
			ghost_timer -= delta
			if ghost_timer <= 0.0:
				spawn_afterimage()
				ghost_timer = ghost_interval

	# 冲刺冷却倒计时
	if dash_timer > 0.0:
		dash_timer -= delta

	# 朝向鼠标
	face_mouse(delta)

	# 警觉值自然下降，如果可以的话
	if can_downalert and alertness > 0.0:
		alert_down(delta)

	# 统一调用移动函数
	move_and_slide()

# 获取输入方向
func get_input_dir() -> Vector2:
	return Vector2(
		Input.get_action_strength("p_right") - Input.get_action_strength("p_left"),
		Input.get_action_strength("p_down") - Input.get_action_strength("p_up")
	).normalized()

# 朝向鼠标
func face_mouse(delta: float) -> void:
	var mp = get_global_mouse_position()
	var ang = (mp - global_position).angle()
	if abs(angle_difference(rotation, ang)) > 0.1:
		rotation = lerp_angle(rotation, ang, 7 * delta)

# 警觉值相关
func _on_Timer_reset_alertness_timeout() -> void:
	can_downalert = true

func alert_down(delta: float) -> void:
	alertness -= alertness_downspeed * delta
	alertness = max(alertness, 0.0)

# 残影相关
func spawn_afterimage() -> void:
	var afterimage = $AfterImage.duplicate() as Sprite2D
	afterimage.name = "afterimage"
	afterimage.global_position = global_position
	afterimage.global_rotation = rotation
	afterimage.z_index = z_index + 1
	get_parent().add_child(afterimage)

	# ShaderMaterial 材质
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shader/player_Afterimage.gdshader")
	mat.set_shader_parameter("time", 0.0)
	afterimage.material = mat

	# 渐变动画及其销毁（tween）
	var t := create_tween()
	t.tween_property(mat, "shader_parameter/time", 1.0, 0.5) # 渐变持续时间
	t.tween_callback(Callable(afterimage, "queue_free"))


