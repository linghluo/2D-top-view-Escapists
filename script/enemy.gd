extends CharacterBody2D

var speed: float = 4500.0 # 速度
var vision_range: float = 300.0 # 视野范围
var max_alertness: float = 100.0 # 最大警觉度
var chase_threshold: float = 80.0 # 追击阈值

var player: CharacterBody2D = null # 初始化玩家引用
var is_chasing: bool = false # 初始化是否正在追击
var last_seen_position: Vector2 = Vector2.ZERO # 初始化上次看到玩家的位置
var distance_to_player: float = 0.0 # 初始化玩家距离

var raycasts: Array = []

func _ready():
	player = $"/root/Main/player"
	raycasts = [$Vision/RayCast1, $Vision/RayCast2, $Vision/RayCast3, $Vision/RayCast4, $Vision/RayCast5]

func _physics_process(_delta):
	# 实现转向
	if velocity.length() > 0.1:
		rotation = velocity.angle()
	# 万一没赋值上去(??)
	if player == null:
		player = $"/root/Main/player"
		return
	# 检测玩家是否在视野范围以内
	distance_to_player = position.distance_to(player.position) # 玩家距离
	if distance_to_player < vision_range:
	# 警戒值上升（记得自己做前置判断）
		player.alert_up()
	# 警戒值下降（记得自己做前置判断）
	if player.alertness > 0.1:
		player.alert_down()
	# 测试警戒值变化速率
	print("Alertness: ", player.alertness)
	# if is_chasing:
	#	move_towards(last_seen_position, delta)
	# else:
	# 			patrol()
	# Check for obstacles using raycasts

func move_towards(target_position: Vector2, delta: float):
	var direction = (target_position - position).normalized()
	velocity = direction * speed * delta
	move_and_slide()


# func patrol():
# 	# Example patrol logic: move left and right
# 	var patrol_direction = Vector2.LEFT if int(position.x) % 200 < 100 else Vector2.RIGHT
# 	velocity = patrol_direction * speed
# 	move_and_slide()
