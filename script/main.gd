extends Node2D
@onready var music_player: AudioStreamPlayer = $MusicPlayer
var wait_time: float = 5.0 # 等待时间shij

func _ready():
    $Sprite_main.texture = $SubContainer/Sub.get_texture()
    music_player.play()
    music_player.finished.connect(_on_music_finished)

func _process(_delta):
    var mat = $Sprite_main.material
    if mat and mat is ShaderMaterial:
        mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

func _on_music_finished():
    print("音乐播放完毕，等待5秒...")
    await get_tree().create_timer(wait_time).timeout
    music_player.play()
