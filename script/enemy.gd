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
