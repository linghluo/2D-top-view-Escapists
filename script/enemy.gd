extends CharacterBody2D

# GDScript file for enemy AI behavior in a 2D game

var speed: float = 4500.0 # 速度
var vision_range: int = 300 # 视野范围
var alertness: int = 0 # 警觉度
var max_alertness: int = 100 # 最大警觉度
var chase_threshold: int = 80 # 追击阈值
var player: CharacterBody2D = null # 玩家引用
var is_chasing: bool = false # 是否正在追击
var last_seen_position: Vector2 = Vector2.ZERO # 上次看到玩家的位置

var raycasts: Array = []

func _ready():
	player = $"/root/Main/player"
	print(player)
	raycasts = [$Vision/RayCast1, $Vision/RayCast2, $Vision/RayCast3, $Vision/RayCast4, $Vision/RayCast5]

func _physics_process(delta):
	if velocity.length() > 0.1:
		rotation = velocity.angle()
	if player == null:
		player = $"/root/Main/player"
		return
	# 检测玩家是否在视野范围以内
	var distance_to_player = position.distance_to(player.position)
	if distance_to_player < vision_range:
		alertness += 1 # 玩家在视野内持续增加警觉度
		if alertness >= chase_threshold: # 达到追击阈值
			is_chasing = true # 开始追击
			alertness = max_alertness # 重置警觉度
			last_seen_position = player.position
	else:
		alertness -= 1
		if alertness <= 0:
			is_chasing = false

	if is_chasing:
		move_towards(last_seen_position, delta)
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
