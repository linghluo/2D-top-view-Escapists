extends CharacterBody2D

var speed: float = 4500.0 # 速度
var vision_range: float = 300.0 # 视野范围
var max_alertness: float = 100.0 # 最大警觉度
var chase_threshold: float = 80.0 # 追击阈值
@export var alertness_upspeed: float = 20.0 # 警觉值增长速度
@export var alertness_downspeed: float = 2.5 # 警戒值减少速度

var player: CharacterBody2D = null # 初始化玩家引用
var is_chasing: bool = false # 初始化是否正在追击
var last_seen_position: Vector2 = Vector2.ZERO # 初始化上次看到玩家的位置
var distance_to_player: float = 0.0 # 初始化玩家距离
var is_in_vision: bool = false # 初始化是否在视野范围内

var raycasts: Array = []

func _ready():
	player = $"/root/Main/player"
	raycasts = [$RayCast1, $RayCast2, $RayCast3, $RayCast4, $RayCast5]

func _physics_process(delta):
	distance_to_player = position.distance_to(player.position) # 玩家距离
	# 实现转向
	if velocity.length() > 0.1:
		rotation = velocity.angle()
	# 检测玩家是否在视野范围以内
	for raycast in raycasts:
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider == player:
				is_in_vision = true # 玩家在视野范围内
				last_seen_position = player.position # 更新上次看到玩家的位置
				alert_up(delta) # 警戒值上升
				break
		else:
			is_in_vision = false # 玩家不在视野范围内
	# 如果玩家不在视野范围内，且警戒值大于0.1，则开始下降
	if player.alertness > 0.1 and not is_in_vision:
		alert_down(delta)
	# 追击状态开始与结束
	if player.alertness > chase_threshold:
		is_chasing = true
	else :
		is_chasing = false
	# 测试警戒值变化速率
	print("Alertness: ", player.alertness)
	# 追击状态
	if is_chasing:
		move_towards(last_seen_position, delta)
	# else:
	# 			patrol()

# 追击函数
func move_towards(target_position: Vector2, delta: float):
	var direction = (target_position - position).normalized()
	velocity = direction * speed * delta
	move_and_slide()

# 警觉值增加方法
func alert_up(delta: float):
	player.alertness += alertness_upspeed * delta
	if player.alertness > max_alertness:
		player.alertness = max_alertness

# 警戒值减少方法
func alert_down(delta: float):
	player.alertness -= alertness_downspeed * delta
	if player.alertness < 0:
		player.alertness = 0


# func patrol():
# 	# Example patrol logic: move left and right
# 	var patrol_direction = Vector2.LEFT if int(position.x) % 200 < 100 else Vector2.RIGHT
# 	velocity = patrol_direction * speed
# 	move_and_slide()
