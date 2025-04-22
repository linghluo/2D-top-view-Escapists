extends CharacterBody2D

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D # 导航代理

@export var normal_speed: float = 60.0 # 正常速度
@export var chase_speed: float = 60.0 # 追击速度
@export var search_speed: float = 60.0 # 搜寻速度
var max_alertness: float = 120.0 # 最大警觉度
var chase_threshold1: float = 40.0 # 警戒状态阈值
var chase_threshold2: float = 70.0 # 追击状态阈值
@export var alertness_upspeed: float = 15.0 # 警觉值增长速度

var speed: float = 0.0 # 初始化速度
var initial_position: Vector2 # 声明初始位置变量，用来保存敌人初始位置
var player: CharacterBody2D = null # 初始化玩家引用
var last_seen_position: Vector2 = Vector2.ZERO # 初始化上次看到玩家的位置
var distance_to_player: float = 0.0 # 初始化玩家距离
var searching_in_progress: bool = false # 防止被中途打断的标志（状态机searching）
var tag_loss: int = 0 # 初始化跟丢函数内tag标签（状态机searching）
var time_loss: float = 0 # 初始化跟丢函数内time标签（状态机searching）
var player_visible: bool = false # 初始化射线检测函数内tag标签（视线检测）
var target_rotation: float = 0.0 # 初始化目标旋转角度
var raycasts: Array = [] # 初始化射线数组
var face_velocity: bool = false # 是否根据速度方向转头

# 状态机
enum State {initalize, chasing, searching, alert}
var state = State.initalize # 初始化状态机

var time_since_last_noise: float = 0.0 # 记录进入alert状态后没有收到噪音的时间

func _ready():
	player = $"/root/Main/player"
	raycasts = [$RayCast1, $RayCast2, $RayCast3, $RayCast4, $RayCast5, $RayCast6, $RayCast7, $RayCast8, $RayCast9]
	add_to_group("enemies")
	initial_position = global_position # 保存初始位置

func _physics_process(delta):
	# 实现转向
	if face_velocity and velocity.length() > 0.1 and state != State.chasing:
		target_rotation = velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, 3 * delta)

	# 状态机
	match state:
		State.initalize:
			speed = normal_speed
			initalize_Static()
			print("initalize")

		State.chasing:
			speed = chase_speed
			move_towards(last_seen_position)
			var mp = last_seen_position
			var ang = (mp - global_position).angle()
			if abs(angle_difference(rotation, ang)) > 0.1:
				rotation = lerp_angle(rotation, ang, 10 * delta)
			print("chasing")

		State.searching:
			speed = search_speed
			loss_vision(last_seen_position, delta)
			print("searching")

		State.alert:
			speed = normal_speed
			# 计时
			time_since_last_noise += delta
			# 听到噪音间隔
			if time_since_last_noise > 8.0:
				initalize_Static()
			print("alert")

	# 检测玩家是否在视野范围内
	player_visible = false
	for raycast in raycasts:
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider == player:
				player_visible = true
				player.can_downalert = false
				last_seen_position = player.position
				searching_in_progress = false # 害tm的看！
				alert_up(delta)

				rotation = lerp_angle(rotation, (player.global_position - global_position).angle(), 10 * delta)

				break

	# 状态切换逻辑
	if player_visible and player.alertness > chase_threshold2:
		state = State.chasing

	elif state == State.chasing:
		var distance_to_last_seen = global_position.distance_to(last_seen_position)
		if distance_to_last_seen < 5.0:
			state = State.searching
			tag_loss = 0
			time_loss = 0.0
			searching_in_progress = true # 在找了在找了

	elif player.alertness > chase_threshold1 and state not in [State.chasing, State.searching]:
		state = State.alert

	elif player.alertness <= chase_threshold1 and state == State.alert:
		state = State.initalize

	move_and_slide()

# 警觉值增加方法
func alert_up(delta: float):
	player.alertness += alertness_upspeed * delta
	if player.alertness > max_alertness:
		player.alertness = max_alertness

# 接受噪音方法
func hear_noise(noise_position: Vector2, noise_strength: float):
	var distance = global_position.distance_to(noise_position)
	if distance < noise_strength * 3.0:
		player.alertness += 0.001 * noise_strength
		if player.alertness > max_alertness:
			player.alertness = max_alertness
		if state in [State.alert, State.searching]:
			last_seen_position = noise_position
			state = State.searching
			tag_loss = 0
			time_loss = 0.0
			searching_in_progress = true
			time_since_last_noise = 0.0 # 重置噪音计时器

# 追击移动
func move_towards(target_position: Vector2):
	face_velocity = true
	navigation_agent_2d.target_position = target_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * speed
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)

# ==== 初始化状态 ====

# 一----静态敌人
func initalize_Static():
	# 妈妈妈妈，这里有花！
	var distance_to_home = global_position.distance_to(initial_position)
	if distance_to_home > 5.0: # 给我回家！！！
		move_towards(initial_position) # 呜呜呜~~~
	else:
		velocity = Vector2.ZERO

# 二----动态巡逻敌人

# ==== 初始化状态 ====

# 不再是跟丢啦！！函数了，苦哇苦，是搜寻函数
func loss_vision(target_position: Vector2, delta: float):
	match tag_loss:
		0:
			face_velocity = true
			move_towards(target_position)
			if global_position.distance_to(target_position) < 5.0:
				velocity = Vector2.ZERO
				time_loss += delta
				if time_loss > 1.0:
					tag_loss = 1
					time_loss = 0.0

		1:
			face_velocity = false
			velocity = Vector2.ZERO
			if time_loss == 0.0:
				target_rotation = rotation + deg_to_rad(90)
			rotation = lerp_angle(rotation, target_rotation, 1 * delta)
			time_loss += delta
			if time_loss > 5.0 and abs(angle_difference(rotation, target_rotation)) < 0.05:
				tag_loss = 2
				time_loss = 0.0

		2:
			face_velocity = false
			velocity = Vector2.ZERO
			if time_loss == 0.0:
				target_rotation = rotation + deg_to_rad(180)
			rotation = lerp_angle(rotation, target_rotation, 2 * delta)
			time_loss += delta
			if time_loss > 7.0 and abs(angle_difference(rotation, target_rotation)) < 0.05:
				tag_loss = 3
				time_loss = 0.0

		3:
			face_velocity = false
			velocity = Vector2.ZERO
			if time_loss == 0.0:
				target_rotation = rotation + deg_to_rad(180)
			rotation = lerp_angle(rotation, target_rotation, 2 * delta)
			time_loss += delta
			if time_loss > 7.0 and abs(angle_difference(rotation, target_rotation)) < 0.05:
				tag_loss = 4
				time_loss = 0.0

		4:
			face_velocity = false
			velocity = Vector2.ZERO
			if time_loss == 0.0:
				target_rotation = rotation + deg_to_rad(180)
			rotation = lerp_angle(rotation, target_rotation, 2 * delta)
			time_loss += delta
			if time_loss > 7.0 and abs(angle_difference(rotation, target_rotation)) < 0.05:
				tag_loss = 5
				time_loss = 0.0

		5:
			face_velocity = false
			velocity = Vector2.ZERO
			time_loss += delta
			if time_loss > 1.0:
				state = State.alert
				tag_loss = 0
				time_loss = 0.0
				searching_in_progress = false # 真找不到啊！

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
