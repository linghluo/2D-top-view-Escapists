extends Area2D

@export var checkpoint_position: Vector2 = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.checkpoint = global_position
