# 相机跟随主角
extends Camera2D

var player: CharacterBody2D

func _ready():
	player = $"/root/Main/players/player"
	# 相机缩放（原定的1080p有点大了）
	zoom = Vector2(2.0, 2.0)

func _process(_delta):
	global_position = player.global_position
