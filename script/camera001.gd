# 相机跟随主角
extends Camera2D

var player: CharacterBody2D

func _ready():
    player = $"/root/Main/player"
    # 相机缩放（原定的1080p有点大了）
    zoom = Vector2(1.5, 1.5)

func _process(_delta):
    global_position = player.global_position
