extends CharacterBody2D

# 信号
signal player_respawned # 玩家重生信号（目前只有enemy接受）

@export var normal_speed: float = 100.0 # 正常行走速度
@export var sneak_speed: float = 50.0 # 潜行行走速度
@export var dash_speed: float = 1000.0 # 冲刺速度（像素/秒）
@export var dash_distance: float = 150.0 # 冲刺固定距离（像素）
@export var dash_charge_time: float = 0.5 # 蓄力时长（秒）
@export var dash_cooldown: float = 9.0 # 冲刺冷却（秒）
@export var ghost_interval: float = 0.02 # 残影生成间隔（秒）
@onready var water_effect: Sprite2D = $Water_dash # 水波纹效果图
@onready var dash_ready_icon: Sprite2D = $Cooling_dash # 冲刺准备完成图标
@onready var attack_effect: Sprite2D = $Attack # 攻击效果
@onready var attack_timer := $AttackTimer # 攻击计时器
@onready var water_noise_sprite := $Water_noise

# 冲刺系统相关
var dash_charge_timer: float = 0.0 # 蓄力倒计时
var dash_timer: float = 0.0 # 冲刺冷却倒计时
var dash_direction: Vector2 = Vector2.ZERO # 冲刺方向
var dash_start_pos: Vector2 = Vector2.ZERO # 冲刺起点
var dash_end_pos: Vector2 = Vector2.ZERO # 冲刺终点
var ghost_timer: float = 0.0 # 残影生成倒计时
var water_tween: Tween = null # 波纹动画
var has_started_water: bool = false # 是否开始了波纹动画

# 警觉值相关系统
var can_downalert: bool = true # 是否允许警觉值下降
@export var alertness_downspeed: float = 2.0 # 警觉值下降速率 (/秒)
@export var time_can_downalert_speed: float = 20.0 # 重置可降警戒tag时间
@export var max_alertness: float = 120.0
@export var chase_threshold1: float = 40.0
@export var chase_threshold2: float = 70.0
var alertness: float = 0.0 # 警觉值
var visual_alertness: float = 0.0 # 平滑过渡用
@onready var alertness_effect := $"/root/Main/CanvasLayer/alertness"

# 其他系统相关
var checkpoint: Vector2 # 重生点
var dash_timeer: float = 0.0 # 冲刺防卡墙用计时器
var is_attacking = false # 攻击tag
var noise_animation_cooldown_timer: float = 0.0
const NOISE_ANIMATION_COOLDOWN: float = 1.0 # 噪音动画时间限制（/秒）

func _process(delta):
	var smoothing_speed = 3.0
	visual_alertness = lerp(visual_alertness, alertness, delta * smoothing_speed)

	if alertness_effect.material and alertness_effect.material is ShaderMaterial:
		var mat = alertness_effect.material
		mat.set_shader_parameter("alertness_visual", visual_alertness)
		mat.set_shader_parameter("max_alertness", max_alertness)
		mat.set_shader_parameter("threshold1", chase_threshold1)
		mat.set_shader_parameter("threshold2", chase_threshold2)

# 玩家状态机
enum State {normal, sneak, dash_change, dash}
var state: State = State.normal # 初始化状态机

func _ready() -> void:
	add_to_group("player") # 加入玩家组
	$Hitbox.add_to_group("player_hitbox") # 添加到攻击区域组
	# 警觉值重置定时器
	$Timer_reset_alertness.wait_time = time_can_downalert_speed
	$Timer_reset_alertness.start()
	# 初始化
	checkpoint = global_position
	# shader相关的初始化
	water_effect.visible = false
	dash_ready_icon.visible = false

# 重置警觉值下降tag
func _on_timer_reset_alertness_timeout() -> void:
	can_downalert = true

func _physics_process(delta: float) -> void:
	# print("alertness: ", alertness)
	# 清空速度（更好的速度管理）
	velocity = Vector2.ZERO

	# 状态机
	match state:
		State.normal:
			var dir = get_input_dir()
			velocity = dir * normal_speed
			# 正常行走噪音
			if dir != Vector2.ZERO:
				make_noise(global_position, 8.0, 200.0)
			if Input.is_action_pressed("p_sneak"):
				state = State.sneak
			elif Input.is_action_just_pressed("p_dash") and dash_timer <= 0.0:
				state = State.dash_change
				dash_charge_timer = dash_charge_time
				water_effect.visible = false

		State.sneak:
			var dir2 = get_input_dir()
			velocity = dir2 * sneak_speed
			if Input.is_action_just_released("p_sneak"):
				state = State.normal

		State.dash_change:
			dash_charge_timer -= delta
			# 蓄力时缓慢移动（使用的潜行速度的小数倍数）
			var dir3 = get_input_dir()
			velocity = dir3 * sneak_speed * 0.75

			# 蓄力完成，可以冲刺
			if dash_charge_timer <= 0.0:
				# 可以随时准备冲刺的时候播放的超炫酷吊炸天水波纹特效动画
				dash_water_effect()

			if Input.is_action_just_released("p_dash"):
				water_effect.visible = false
				# 停止波纹
				has_started_water = false
				if water_tween:
					water_tween.kill()
					water_tween = null

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
			# 防卡死
			elif dash_timeer >= 0.5:
				dash_timeer = 0.0
				state = State.normal
			else:
				dash_timeer += delta
			# 冲刺噪音
			make_noise(global_position, 20.0, 400.0)
			# 残影
			ghost_timer -= delta
			if ghost_timer <= 0.0:
				spawn_afterimage()
				ghost_timer = ghost_interval

	# 冲刺冷却倒计时
	if dash_timer > 0.0:
		dash_timer -= delta
	# 冷却完成的炫酷动画
	elif not dash_ready_icon.visible:
		dash_ready_icon_effect()
	# 噪音动画冷却
	if noise_animation_cooldown_timer > 0.0:
		noise_animation_cooldown_timer -= delta

	# 攻击！
	if Input.is_action_just_pressed("p_attack"):
		if not is_attacking:
			is_attacking = true
			attack_timer.start()
			$Hitbox.set_deferred("monitoring", true)
			$Hitbox.set_deferred("monitorable", true)
			play_attack_effect()
	
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

# 玩家发出噪音
func make_noise(target_position: Vector2, noise_strength: float, noise_radius: float):
	if noise_animation_cooldown_timer <= 0.0:
		play_noise(noise_radius)
		noise_animation_cooldown_timer = NOISE_ANIMATION_COOLDOWN

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.hear_noise(target_position, noise_strength, noise_radius)

# 玩家的死亡，与新生
func die():
	global_position = checkpoint
	alertness = 0
	dash_timer = 0.0
	can_downalert = true
	state = State.normal
	velocity = Vector2.ZERO
	emit_signal("player_respawned")

# 被抓住了捏，会发生什么呢？
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		die()
	
func _on_attack_timer_timeout() -> void:
	is_attacking = false
	$Hitbox.set_deferred("monitoring", false)
	$Hitbox.set_deferred("monitorable", false)

# =============================================== 以下是动画相关函数 ===============================================
# 攻击！
func play_attack_effect():
	attack_effect.visible = true
	var mat = attack_effect.material
	if mat == null:
		return
	mat.set_shader_parameter("progress", 0.0)

	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/progress", 1.0, 0.3)
	tween.tween_callback(Callable(self, "_on_attack_effect_finished"))

func _on_attack_effect_finished():
	attack_effect.visible = false


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

# 这是我最后的波纹了啊@@@
func dash_water_effect():
	if has_started_water:
		return
	has_started_water = true

	# 初始化状态
	water_effect.visible = true
	water_effect.scale = Vector2.ZERO
	water_effect.modulate.a = 1.0
	water_effect.rotation = 0.0 # 旋转不随着凯凯的操作变化了！（搭嘎，失败哩-哭-）

	water_tween = create_tween()
	water_tween.set_loops() # 给我循环起来！
	water_tween.tween_property(water_effect, "scale", Vector2.ONE * 1.8, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	water_tween.tween_interval(1.0)
	water_tween.tween_property(water_effect, "modulate:a", 0.0, 1.0)

	# 重置，循环
	water_tween.tween_callback(func():
		water_effect.scale = Vector2.ZERO
		water_effect.modulate.a = 1.0
	)

# 可以冲刺的图标效果
func dash_ready_icon_effect():
	dash_ready_icon.visible = true
	dash_ready_icon.scale = Vector2.ZERO

	var t := create_tween()

	t.tween_property(dash_ready_icon, "scale", Vector2.ONE * 1.2, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_method(
		func(p): dash_ready_icon.material.set_shader_parameter("progress", p),
		0.0, 1.0, 3.5
	)

	t.tween_callback(Callable(dash_ready_icon, "hide"))

func play_noise(radius: float):
	water_noise_sprite.scale = Vector2.ZERO
	water_noise_sprite.modulate.a = 1.0
	water_noise_sprite.show()

	var target_scale = radius / water_noise_sprite.texture.get_width() * 2.0

	var tween = create_tween()
	tween.tween_property(water_noise_sprite, "scale", Vector2.ONE * target_scale, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(water_noise_sprite, "modulate:a", 0.0, 0.6)
	tween.tween_callback(Callable(water_noise_sprite, "hide"))
