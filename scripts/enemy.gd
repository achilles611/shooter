extends Node2D

@export var radius: float = 18.0
@export var point_value: int = 2
@export var drop_chance: float = 0.02


func _draw() -> void:
	var glow_color: Color = Color(1.0, 0.85, 0.2, 0.11)
	var fill_color: Color = Color(1.0, 0.9, 0.35, 0.22)
	var outline_color: Color = Color(1.0, 0.95, 0.55, 0.96)

	draw_circle(Vector2.ZERO, radius + 13.0, glow_color)
	draw_circle(Vector2.ZERO, radius + 7.0, Color(glow_color.r, glow_color.g, glow_color.b, 0.18))
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline_color, 2.5, true)
