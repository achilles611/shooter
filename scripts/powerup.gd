extends Node2D

const SCREEN_SIZE := Vector2(1920.0, 1080.0)

@export var fall_speed: float = 180.0
@export var pickup_radius: float = 28.0

var powerup_type: StringName = &"spread"
var bob_time: float = 0.0


func advance(delta: float) -> void:
	bob_time += delta
	position.y += fall_speed * delta
	queue_redraw()

	if global_position.y > SCREEN_SIZE.y + 48.0:
		queue_free()


func _draw() -> void:
	var bubble_alpha: float = 0.78 + sin(bob_time * 3.2) * 0.08
	var bubble_glow: Color = Color(1.0, 1.0, 1.0, 0.12)
	var bubble_outline: Color = Color(1.0, 1.0, 1.0, bubble_alpha)
	var bubble_fill: Color = Color(1.0, 1.0, 1.0, 0.06)

	draw_circle(Vector2.ZERO, pickup_radius + 10.0, bubble_glow)
	draw_circle(Vector2.ZERO, pickup_radius, bubble_fill)
	draw_arc(Vector2.ZERO, pickup_radius, 0.0, TAU, 48, bubble_outline, 2.5, true)
	draw_arc(Vector2(-7.0, -8.0), 9.0, PI * 1.12, PI * 1.88, 14, Color(1.0, 1.0, 1.0, 0.55), 1.4, true)

	match powerup_type:
		&"spread":
			_draw_spread_icon()
		&"wingman":
			_draw_wingman_icon()


func _draw_spread_icon() -> void:
	var bolt: PackedVector2Array = PackedVector2Array([
		Vector2(-4.0, -16.0),
		Vector2(6.0, -16.0),
		Vector2(-1.0, -2.0),
		Vector2(10.0, -2.0),
		Vector2(-8.0, 16.0),
		Vector2(-1.0, 3.0),
		Vector2(-12.0, 3.0),
		Vector2(-4.0, -16.0)
	])
	draw_polyline(bolt, Color(1.0, 0.25, 0.16, 0.96), 3.0, true)
	draw_polyline(bolt, Color(1.0, 0.55, 0.3, 0.2), 9.0, true)


func _draw_wingman_icon() -> void:
	var pillar_color: Color = Color(1.0, 1.0, 1.0, 0.92)
	var glow_color: Color = Color(1.0, 1.0, 1.0, 0.18)
	draw_line(Vector2(-7.0, -14.0), Vector2(-7.0, 14.0), glow_color, 10.0, true)
	draw_line(Vector2(7.0, -14.0), Vector2(7.0, 14.0), glow_color, 10.0, true)
	draw_line(Vector2(-7.0, -14.0), Vector2(-7.0, 14.0), pillar_color, 3.0, true)
	draw_line(Vector2(7.0, -14.0), Vector2(7.0, 14.0), pillar_color, 3.0, true)
