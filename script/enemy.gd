extends CharacterBody2D

# GDScript file for enemy AI behavior in a 2D game

var speed : float = 100
var vision_range : int = 300
var alertness : int = 0
var max_alertness : int = 100
var chase_threshold : int = 80
var player : CharacterBody2D = null
var is_chasing : bool = false
var last_seen_position : Vector2 = Vector2.ZERO

var raycasts : Array = []

func _ready():
	player = $"/root/Main/player"
	print(player)
	raycasts = [$Vision/RayCast1, $Vision/RayCast2, $Vision/RayCast3, $Vision/RayCast4, $Vision/RayCast5]

func _physics_process(_delta):
	if player == null:
		player = $"/root/Main/player"
		return

	var distance_to_player = position.distance_to(player.position)
	if distance_to_player < vision_range:
		alertness += 1
		if alertness >= chase_threshold:
			is_chasing = true
			last_seen_position = player.position
	else:
		alertness -= 1
		if alertness <= 0:
			is_chasing = false

	if is_chasing:
		move_towards(last_seen_position)
	else:
				patrol()
				# Check for obstacles using raycasts
		
func patrol():
	# Example patrol logic: move left and right
	var patrol_direction = Vector2.LEFT if int(position.x) % 200 < 100 else Vector2.RIGHT
	velocity = patrol_direction * speed
	move_and_slide()
	
func move_towards(target_position: Vector2):
	var direction = (target_position - position).normalized()
	velocity = direction * speed
	move_and_slide()
