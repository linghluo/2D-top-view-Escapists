extends Camera2D

@export var player_path: NodePath
@export var speed: float = 0.05
var player: Node2D

var target_limits: Rect2 = Rect2(0, 0, 1000, 1000)
var target_zoom: Vector2 = Vector2(2, 2)

# 使用私有变量存储平滑过渡值（float）
var _smooth_left: float
var _smooth_top: float
var _smooth_right: float
var _smooth_bottom: float

func _ready():
	make_current()
	player = get_node(player_path)

	# 初始化平滑变量为当前相机的限制值
	_smooth_left = float(limit_left)
	_smooth_top = float(limit_top)
	_smooth_right = float(limit_right)
	_smooth_bottom = float(limit_bottom)

	# 连接所有 CameraArea
	for area in get_tree().get_nodes_in_group("camera_areas"):
		if not area.is_connected("camera_area_entered", Callable(self, "set_camera_area")):
			area.connect("camera_area_entered", Callable(self, "set_camera_area"))

func set_camera_area(limits: Rect2, new_zoom: Vector2):
	target_limits = limits
	target_zoom = new_zoom

func _process(_delta):
	# 平滑更新 float
	_smooth_left = lerp(_smooth_left, target_limits.position.x, speed)
	_smooth_top = lerp(_smooth_top, target_limits.position.y, speed)
	_smooth_right = lerp(_smooth_right, target_limits.position.x + target_limits.size.x, speed)
	_smooth_bottom = lerp(_smooth_bottom, target_limits.position.y + target_limits.size.y, speed)
	# 取整赋值（非得int是吧）
	limit_left = int(_smooth_left)
	limit_top = int(_smooth_top)
	limit_right = int(_smooth_right)
	limit_bottom = int(_smooth_bottom)

	# 平滑缩放
	zoom = zoom.lerp(target_zoom, speed)

	if player:
		var pos = player.global_position
		global_position = pos.clamp(
			Vector2(limit_left, limit_top),
			Vector2(limit_right, limit_bottom)
		)
