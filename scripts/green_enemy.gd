extends Node2D

const SCREEN_SIZE := Vector2(1920.0, 1080.0)
const EDGE_PADDING := 80.0

@export var radius: float = 22.0
@export var point_value: int = 5
@export var drop_chance: float = 0.05
@export var horizontal_speed: float = 430.0
@export var dive_speed: float = 620.0
@export var oscillation_amplitude: float = 40.0
@export var oscillation_frequency: float = 3.4

var travel_direction: float = 1.0
var oscillation_phase: float = 0.0
var base_y: float = 160.0
var travel_time: float = 0.0
var edge_crosses: int = 0
var is_diving: bool = false
var dive_velocity: Vector2 = Vector2.ZERO


func setup(start_position: Vector2, direction: float, phase: float) -> void:
	position = start_position
	base_y = start_position.y
	travel_direction = direction
	oscillation_phase = phase


func advance(delta: float, player_position: Vector2) -> void:
	if is_diving:
		var desired_velocity: Vector2 = (player_position - global_position).normalized() * dive_speed
		dive_velocity = dive_velocity.lerp(desired_velocity, minf(delta * 1.35, 1.0))
		position += dive_velocity * delta
		rotation = dive_velocity.angle() + PI * 0.5
	else:
		travel_time += delta
		position.x += travel_direction * horizontal_speed * delta
		position.y = base_y + sin(travel_time * oscillation_frequency + oscillation_phase) * oscillation_amplitude

		if position.x >= SCREEN_SIZE.x - EDGE_PADDING and travel_direction > 0.0:
			position.x = SCREEN_SIZE.x - EDGE_PADDING
			travel_direction = -1.0
			edge_crosses += 1
		elif position.x <= EDGE_PADDING and travel_direction < 0.0:
			position.x = EDGE_PADDING
			travel_direction = 1.0
			edge_crosses += 1

		if edge_crosses >= 3:
			is_diving = true
			dive_velocity = (player_position - global_position).normalized() * dive_speed

	if (
		global_position.x < -120.0
		or global_position.x > SCREEN_SIZE.x + 120.0
		or global_position.y > SCREEN_SIZE.y + 120.0
	):
		queue_free()


func _draw() -> void:
	var fur_color: Color = Color(0.28, 0.82, 0.32, 0.72)
	var glow_color: Color = Color(0.25, 1.0, 0.4, 0.12)
	var fill_color: Color = Color(0.44, 0.92, 0.48, 0.34)
	var outline_color: Color = Color(0.84, 1.0, 0.86, 0.98)

	for tuft_index in 18:
		var angle: float = (TAU / 18.0) * float(tuft_index)
		var inner: Vector2 = _ellipse_point(angle, radius - 1.5)
		var outer: Vector2 = _ellipse_point(angle, radius + 8.0 + sin(float(tuft_index) * 1.7) * 4.0)
		draw_line(inner, outer, fur_color, 3.2, true)
		draw_circle(outer, 1.5, Color(0.62, 1.0, 0.66, 0.45))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.8, 0.84))
	draw_circle(Vector2.ZERO, radius, glow_color)
	draw_circle(Vector2.ZERO, radius - 4.0, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline_color, 2.3, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var eye_white: Color = Color(1.0, 1.0, 1.0, 0.98)
	var pupil_color: Color = Color(0.06, 0.06, 0.06, 1.0)
	var eye_glow: Color = Color(0.9, 1.0, 0.9, 0.18)
	var left_eye: Vector2 = Vector2(-16.0, -4.0)
	var right_eye: Vector2 = Vector2(16.0, -4.0)

	draw_circle(left_eye, 10.0, eye_glow)
	draw_circle(right_eye, 10.0, eye_glow)
	draw_circle(left_eye, 7.0, eye_white)
	draw_circle(right_eye, 7.0, eye_white)
	draw_circle(left_eye + Vector2(1.5, 1.2), 3.0, pupil_color)
	draw_circle(right_eye + Vector2(1.5, 1.2), 3.0, pupil_color)
	draw_arc(Vector2.ZERO, 13.0, 0.2, PI - 0.2, 18, Color(0.08, 0.22, 0.08, 0.75), 2.0, true)


func _ellipse_point(angle: float, distance: float) -> Vector2:
	return Vector2(cos(angle) * distance * 1.72, sin(angle) * distance * 0.82)
