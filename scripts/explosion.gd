extends Node2D

@export var duration: float = 0.32

var elapsed: float = 0.0


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

	if elapsed >= duration:
		queue_free()


func _draw() -> void:
	var t: float = clampf(elapsed / duration, 0.0, 1.0)
	var white_radius: float = lerpf(8.0, 44.0, t)
	var red_radius: float = lerpf(6.0, 34.0, t)
	var alpha: float = 1.0 - t

	draw_arc(
		Vector2.ZERO,
		white_radius,
		0.0,
		TAU,
		48,
		Color(1.0, 1.0, 1.0, alpha),
		4.0,
		true
	)
	draw_arc(
		Vector2.ZERO,
		red_radius,
		0.0,
		TAU,
		48,
		Color(1.0, 0.25, 0.15, alpha * 0.95),
		3.0,
		true
	)
