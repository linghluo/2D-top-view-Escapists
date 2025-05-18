extends Area2D

@export var zoom: Vector2 = Vector2(2, 2)
signal camera_area_entered(limits: Rect2, zoom: Vector2)

func _ready():
	add_to_group("camera_areas")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.name != "player":
		return

	if not has_node("CollisionShape2D"):
		return

	var shape = $CollisionShape2D.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var global_xform = $CollisionShape2D.get_global_transform()

		# 矩形四角的空间坐标
		var corners = [
			Vector2(-extents.x, -extents.y),
			Vector2(extents.x, -extents.y),
			Vector2(extents.x, extents.y),
			Vector2(-extents.x, extents.y)
		]

		# 全局坐标
		var global_points = []
		for c in corners:
			global_points.append(global_xform * c)

		# 最小包围矩形
		var rect = Rect2(global_points[0], Vector2.ZERO)
		for p in global_points:
			rect = rect.expand(p)

		emit_signal("camera_area_entered", rect, zoom)
