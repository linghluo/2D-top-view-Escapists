extends Node2D

func _ready():
    $Sprite_main.texture = $SubContainer/Sub.get_texture()

func _process(_delta):
    var mat = $Sprite_main.material
    if mat and mat is ShaderMaterial:
        mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
