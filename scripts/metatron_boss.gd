extends Node2D

const SCREEN_SIZE := Vector2(1920.0, 1080.0)
const TOP_AREA := Rect2(Vector2(150.0, 80.0), Vector2(1620.0, 320.0))
const BossAttackSound = preload("res://voicebosch-the-moses-laser-cannon-182841.mp3")
const BOSS_ATTACK_SOUND_START := 12.0

@export var radius: float = 82.0
@export var point_value: int = 50
@export var drop_chance: float = 0.0
@export var max_health: int = 200
@export var move_speed: float = 360.0
@export var charge_duration: float = 2.0
@export var beam_duration: float = 3.0
@export var beam_width: float = SCREEN_SIZE.x / 5.0
@export var beam_turn_rate: float = 1.1
@export var attack_cycle_time: float = 3.6

var health: int = max_health
var velocity: Vector2 = Vector2(200.0, 165.0)
var attack_timer: float = 0.0
var state: StringName = &"moving"
var charge_timer: float = 0.0
var beam_timer: float = 0.0
var beam_direction: Vector2 = Vector2.DOWN
var bubble_count: int = 18
var bubble_spin_time: float = 0.0
var attack_audio: AudioStreamPlayer


func _ready() -> void:
	health = max_health
	velocity = velocity.normalized() * move_speed
	attack_audio = AudioStreamPlayer.new()
	attack_audio.stream = BossAttackSound
	attack_audio.volume_db = -4.0
	add_child(attack_audio)


func advance(delta: float, player_position: Vector2) -> void:
	bubble_spin_time += delta

	match state:
		&"moving":
			attack_timer += delta
			_move_and_bounce(delta)
			if attack_timer >= attack_cycle_time:
				state = &"charging"
				charge_timer = charge_duration
		&"charging":
			charge_timer = maxf(charge_timer - delta, 0.0)
			if charge_timer <= 0.0:
				state = &"firing"
				beam_timer = beam_duration
				beam_direction = (player_position - global_position).normalized()
				_play_attack_sound()
		&"firing":
			attack_timer = 0.0
			_move_and_bounce(delta)
			beam_timer = maxf(beam_timer - delta, 0.0)
			var desired_direction: Vector2 = (player_position - global_position).normalized()
			beam_direction = beam_direction.slerp(desired_direction, minf(delta * beam_turn_rate, 1.0)).normalized()
			if beam_timer <= 0.0:
				state = &"moving"

	queue_redraw()


func take_hit() -> bool:
	health = maxi(health - 1, 0)
	queue_redraw()
	return health <= 0


func is_beam_active() -> bool:
	return state == &"firing" and beam_timer > 0.0


func is_charging() -> bool:
	return state == &"charging" and charge_timer > 0.0


func get_beam_origin() -> Vector2:
	return global_position


func get_beam_direction() -> Vector2:
	return beam_direction


func _play_attack_sound() -> void:
	if attack_audio == null or attack_audio.stream == null:
		return

	attack_audio.stop()
	attack_audio.play(BOSS_ATTACK_SOUND_START)


func _move_and_bounce(delta: float) -> void:
	position += velocity * delta

	if position.x <= TOP_AREA.position.x + radius and velocity.x < 0.0:
		position.x = TOP_AREA.position.x + radius
		velocity.x *= -1.0
	elif position.x >= TOP_AREA.end.x - radius and velocity.x > 0.0:
		position.x = TOP_AREA.end.x - radius
		velocity.x *= -1.0

	if position.y <= TOP_AREA.position.y + radius and velocity.y < 0.0:
		position.y = TOP_AREA.position.y + radius
		velocity.y *= -1.0
	elif position.y >= TOP_AREA.end.y - radius and velocity.y > 0.0:
		position.y = TOP_AREA.end.y - radius
		velocity.y *= -1.0


func _draw() -> void:
	var outer_nodes: Array[Vector2] = _get_outer_points(76.0)
	var mid_nodes: Array[Vector2] = _get_outer_points(38.0)
	var core_color: Color = Color(0.66, 0.9, 1.0, 0.95)
	var glow_color: Color = Color(0.18, 0.66, 1.0, 0.16)
	var line_color: Color = Color(0.75, 0.96, 1.0, 0.9)

	if is_charging():
		_draw_charge_bubbles()

	if is_beam_active():
		_draw_beam()

	for width in [20.0, 12.0]:
		_draw_metatron_lines(outer_nodes, mid_nodes, glow_color, width)

	_draw_metatron_lines(outer_nodes, mid_nodes, line_color, 2.4)

	for point in mid_nodes:
		draw_circle(point, 7.0, Color(0.86, 0.98, 1.0, 0.92))
	for point in outer_nodes:
		draw_circle(point, 8.0, Color(0.76, 0.94, 1.0, 0.95))
	draw_circle(Vector2.ZERO, 10.0, core_color)

	var health_ratio: float = float(health) / float(max_health)
	draw_arc(Vector2.ZERO, 98.0, -PI * 0.5, -PI * 0.5 + TAU * health_ratio, 64, Color(0.26, 0.9, 1.0, 0.9), 5.0, true)


func _draw_metatron_lines(outer_nodes: Array[Vector2], mid_nodes: Array[Vector2], color: Color, width: float) -> void:
	for index in 6:
		var next_index: int = (index + 1) % 6
		var opposite_index: int = (index + 3) % 6

		draw_line(outer_nodes[index], outer_nodes[next_index], color, width, true)
		draw_line(mid_nodes[index], mid_nodes[next_index], color, width, true)
		draw_line(outer_nodes[index], outer_nodes[opposite_index], color, width, true)
		draw_line(outer_nodes[index], mid_nodes[index], color, width, true)
		draw_line(outer_nodes[index], mid_nodes[next_index], color, width, true)
		draw_line(mid_nodes[index], Vector2.ZERO, color, width, true)


func _draw_charge_bubbles() -> void:
	var charge_progress: float = 1.0 - (charge_timer / charge_duration)

	for bubble_index in bubble_count:
		var orbit_angle: float = (TAU / float(bubble_count)) * float(bubble_index) + bubble_spin_time * 1.9
		var orbit_radius: float = lerpf(138.0, 14.0, charge_progress) + sin(float(bubble_index) * 1.8 + bubble_spin_time * 5.0) * 10.0
		var bubble_position: Vector2 = Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
		var bubble_size: float = lerpf(7.5, 3.0, charge_progress)
		draw_circle(bubble_position, bubble_size + 3.0, Color(0.52, 0.88, 1.0, 0.12))
		draw_circle(bubble_position, bubble_size, Color(0.88, 0.98, 1.0, 0.88))


func _draw_beam() -> void:
	var beam_length: float = 2400.0
	var forward: Vector2 = beam_direction.normalized()
	var side: Vector2 = Vector2(-forward.y, forward.x) * (beam_width * 0.5)
	var start: Vector2 = Vector2.ZERO
	var end: Vector2 = forward * beam_length
	var points: PackedVector2Array = PackedVector2Array([
		start + side,
		end + side,
		end - side,
		start - side,
	])

	draw_colored_polygon(points, Color(0.45, 0.9, 1.0, 0.18))
	draw_line(start, end, Color(0.84, 0.98, 1.0, 0.88), 12.0, true)


func _get_outer_points(distance: float) -> Array[Vector2]:
	var points: Array[Vector2] = []

	for point_index in 6:
		var angle: float = -PI * 0.5 + (TAU / 6.0) * float(point_index)
		points.append(Vector2.RIGHT.rotated(angle) * distance)

	return points
