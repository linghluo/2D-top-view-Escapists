extends CharacterBody2D

var speed = 150
var vision_range = 300
var alertness = 0
var max_alertness = 100
var chase_threshold = 80
var player = null
var is_chasing = false
var last_seen_position = Vector2.ZERO

var raycasts: Array = []

func _ready():
	player = get_node("/root/Main/player")
	print(player)
	raycasts = [$Vision/RayCast1, $Vision/RayCast2, $Vision/RayCast3, $Vision/RayCast4, $Vision/RayCast5]

func _physics_process(delta):
	if is_player_in_vision():
		increase_alertness()
	else:
		reset_alertness()

	if is_chasing:
		chase_player(delta)
	else:
		self.velocity = Vector2.ZERO

	move_and_slide()

func is_player_in_vision() -> bool:
	for raycast in raycasts:
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider == player and !is_obstacle_between(raycast):
				print(raycast.name)
				return true
	return false


func is_obstacle_between(raycast: RayCast2D) -> bool:
	return raycast.is_colliding() and raycast.get_collider() != player

func increase_alertness():
	alertness += 1
	if alertness >= chase_threshold:
		start_chasing()

func reset_alertness():
	alertness = max(0, alertness - 1)

func start_chasing():
	is_chasing = true
	last_seen_position = player.position
	print("追击")


func chase_player(_delta):
	var direction_to_player = (player.position - position).normalized()
	self.velocity = direction_to_player * speed
