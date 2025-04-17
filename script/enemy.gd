extends CharacterBody2D

var speed: float = 2000.0 # 速度
var vision_range: float = 300.0 # 视野范围
var max_alertness: float = 100.0 # 最大警觉度
var chase_threshold: float = 80.0 # 追击阈值
@export var alertness_upspeed: float = 20.0 # 警觉值增长速度

var player: CharacterBody2D = null # 初始化玩家引用
var last_seen_position: Vector2 = Vector2.ZERO # 初始化上次看到玩家的位置
var distance_to_player: float = 0.0 # 初始化玩家距离
var tag_loss: int = 0 # 初始化跟丢函数内tag标签（状态机searching）
var time_loss: float = 0 # 初始化跟丢函数内time标签（状态机searching）
var player_visible: bool = false # 初始化射线检测函数内tag标签（视线检测）
var target_rotation: float = 0.0 # 初始化目标旋转角度
var raycasts: Array = [] # 初始化射线数组

# 状态机
enum State {initalize, chasing, searching}
var state = State.initalize # 初始化状态机状态

func _ready():
	player = $"/root/Main/player"
	raycasts = [$RayCast1, $RayCast2, $RayCast3, $RayCast4, $RayCast5]

func _physics_process(delta):
	distance_to_player = position.distance_to(player.position) # 获取self与玩家距离值
	# 实现转向
	if velocity.length() > 0.1:
		rotation = velocity.angle()
	# 状态机匹配放置
	match state:
		State.initalize:
			initalize()
			print("initalize")
		State.chasing:
			move_towards(last_seen_position, delta)
			print("chasing")
		State.searching:
			loss_vision(last_seen_position, delta)
			print("searching")
	# 检测玩家是否在视野范围以内
	player_visible = false
	for raycast in raycasts:
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider == player:
				player_visible = true
				player.can_downalert = false # 如果玩家在视野范围内,则警戒值不可以开始下降
				last_seen_position = player.position # 更新上次看到玩家的位置
				alert_up(delta) # 警戒值上升
				break
	# 状态切换逻辑
	if player_visible:
		if player.alertness > chase_threshold:
			state = State.chasing
	else:
		# 如果原来是 chasing 状态，现在看不到玩家了，就转为searching
		if state == State.chasing:
			state = State.searching


	# 跟丢了
	
	# 测试警戒值变化速率
	print("Alertness: ", player.alertness)

# 警觉值增加方法
func alert_up(delta: float):
	player.alertness += alertness_upspeed * delta
	if player.alertness > max_alertness:
		player.alertness = max_alertness

# 追击函数
func move_towards(target_position: Vector2, delta: float):
	var direction = (target_position - position).normalized() # 计算目标方向
	velocity = direction * speed * delta # 设置速度方向
	move_and_slide() # 执行移动

# 自然状态函数
func initalize():
	pass

# 跟丢啦！！状态函数
func loss_vision(target_position: Vector2, delta: float):
	var distance_to_target = position.distance_to(target_position)
	var target_loss = 10.0 # 允许接近目标的距离（可调）

	match tag_loss:
		0:
			move_towards(target_position, delta)
			move_and_slide()
			if distance_to_target < target_loss:
				tag_loss = 1
				time_loss = 0.0
				velocity = Vector2.ZERO

		1:
			velocity = Vector2.ZERO
			move_and_slide()
			if time_loss == 0.0:
				target_rotation = rotation + deg_to_rad(90)
			rotation = lerp_angle(rotation, target_rotation, 2 * delta)
			time_loss += delta
			if abs(rotation - target_rotation) < 0.1 or time_loss >= 5.0:
				tag_loss = 2
				time_loss = 0.0

		2:
			velocity = Vector2.ZERO
			move_and_slide()
			if time_loss == 0.0:
				target_rotation = rotation - deg_to_rad(180)
			rotation = lerp_angle(rotation, target_rotation, 2 * delta)
			time_loss += delta
			if abs(rotation - target_rotation) < 0.1 or time_loss >= 10.0:
				tag_loss = 3
				time_loss = 0.0

		3:
			velocity = Vector2.ZERO
			move_and_slide()
			state = State.initalize
			tag_loss = 0
			time_loss = 0.0
