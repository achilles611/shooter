extends Node2D

signal shots_fired(shots)

const SCREEN_SIZE := Vector2(1080, 1920)
const HORIZONTAL_PADDING := 24.0
const TOP_BOUND := SCREEN_SIZE.y * 0.75 + 16.0
const BOTTOM_BOUND := SCREEN_SIZE.y - 34.0
const TOUCH_ZONE_TOP := SCREEN_SIZE.y * 0.75
const MAX_BEAM_COUNT := 12
const MAX_TOTAL_SHIPS := 6
const MOBILE_DRAG_SPEED_MULTIPLIER := 1.18

@export var move_speed: float = 820.0
@export var shot_cooldown: float = 0.14
@export var pickup_radius: float = 38.0
@export var hit_radius: float = 30.0

var cooldown_remaining: float = 0.0
var beam_count: int = 2
var wingman_count: int = 0
var is_active: bool = true
var active_touch_id: int = -1
var using_pointer_drag: bool = false
var pointer_target_position: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if not is_active:
		return

	_update_movement(delta)
	_update_shooting(delta)


func _update_movement(delta: float) -> void:
	if using_pointer_drag:
		var clamped_target: Vector2 = _clamp_to_play_area(pointer_target_position)
		position = position.move_toward(clamped_target, move_speed * MOBILE_DRAG_SPEED_MULTIPLIER * delta)
	else:
		var input_vector: Vector2 = Vector2(
			_get_axis([KEY_A, KEY_LEFT], [KEY_D, KEY_RIGHT]),
			_get_axis([KEY_W, KEY_UP], [KEY_S, KEY_DOWN])
		)

		if input_vector.length_squared() > 1.0:
			input_vector = input_vector.normalized()

		position += input_vector * move_speed * delta

	position = _clamp_to_play_area(position)


func _update_shooting(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)

	if cooldown_remaining > 0.0:
		return

	cooldown_remaining = shot_cooldown
	shots_fired.emit(_build_shots())


func apply_powerup(powerup_type: StringName) -> void:
	match powerup_type:
		&"spread":
			beam_count = mini(beam_count + 1, MAX_BEAM_COUNT)
		&"wingman":
			wingman_count = mini(wingman_count + 1, MAX_TOTAL_SHIPS - 1)

	queue_redraw()


func reset_state() -> void:
	beam_count = 2
	wingman_count = 0
	is_active = true
	active_touch_id = -1
	using_pointer_drag = false
	pointer_target_position = position
	queue_redraw()


func set_active(active: bool) -> void:
	is_active = active

	if not is_active:
		active_touch_id = -1
		using_pointer_drag = false


func _build_shots() -> Array:
	var shots: Array = []
	var emitters: Array[Vector2] = _get_emitter_offsets()

	for emitter in emitters:
		if beam_count <= 2:
			var left_origin: Vector2 = to_global(emitter + Vector2(-16.0, -24.0))
			var right_origin: Vector2 = to_global(emitter + Vector2(16.0, -24.0))
			shots.append({
				"origin": left_origin,
				"direction": Vector2.UP,
			})
			shots.append({
				"origin": right_origin,
				"direction": Vector2.UP,
			})
		else:
			_append_beam_pattern(shots, to_global(emitter + Vector2(0.0, -26.0)))

	return shots


func _append_beam_pattern(shots: Array, origin: Vector2) -> void:
	var max_spread_angle: float = 0.85
	var denominator: float = maxf(float(beam_count - 1), 1.0)

	for beam_index in beam_count:
		var t: float = float(beam_index) / denominator
		var angle: float = lerpf(-max_spread_angle, max_spread_angle, t)
		var shot_direction: Vector2 = Vector2.UP.rotated(angle)
		shots.append({
			"origin": origin,
			"direction": shot_direction,
		})


func _get_emitter_offsets() -> Array[Vector2]:
	var offsets: Array[Vector2] = [Vector2.ZERO]
	var wingman_offsets: Array[Vector2] = [
		Vector2(62.0, 0.0),
		Vector2(124.0, 0.0),
		Vector2(186.0, 0.0),
		Vector2(248.0, 0.0),
		Vector2(310.0, 0.0),
	]

	for wingman_index in wingman_count:
		offsets.append(wingman_offsets[wingman_index])

	return offsets


func _get_axis(negative_keys: Array, positive_keys: Array) -> float:
	var axis: float = 0.0

	for key in negative_keys:
		if Input.is_physical_key_pressed(key):
			axis -= 1.0
			break

	for key in positive_keys:
		if Input.is_physical_key_pressed(key):
			axis += 1.0
			break

	return clampf(axis, -1.0, 1.0)


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			if touch_event.position.y >= TOUCH_ZONE_TOP:
				active_touch_id = touch_event.index
				using_pointer_drag = true
				pointer_target_position = touch_event.position
		elif touch_event.index == active_touch_id:
			active_touch_id = -1
			using_pointer_drag = false
	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event
		if drag_event.index == active_touch_id:
			using_pointer_drag = true
			pointer_target_position = drag_event.position
	elif event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.pressed and mouse_button_event.position.y >= TOUCH_ZONE_TOP:
				using_pointer_drag = true
				pointer_target_position = mouse_button_event.position
			elif not mouse_button_event.pressed:
				using_pointer_drag = false
	elif event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event
		if using_pointer_drag:
			pointer_target_position = mouse_motion_event.position


func _clamp_to_play_area(target_position: Vector2) -> Vector2:
	return Vector2(
		clampf(target_position.x, HORIZONTAL_PADDING, SCREEN_SIZE.x - HORIZONTAL_PADDING),
		clampf(target_position.y, TOP_BOUND, BOTTOM_BOUND)
	)


func _draw() -> void:
	var blue_glow: Color = Color(0.2, 0.72, 1.0, 0.12)
	var blue_core: Color = Color(0.5, 0.9, 1.0, 0.9)
	_draw_ship(Vector2.ZERO, 1.0, blue_glow, blue_core)

	var wingman_glow: Color = Color(0.2, 0.72, 1.0, 0.1)
	var wingman_core: Color = Color(0.75, 0.95, 1.0, 0.95)
	var emitter_offsets: Array[Vector2] = _get_emitter_offsets()

	for wingman_index in wingman_count:
		_draw_ship(emitter_offsets[wingman_index + 1], 0.82, wingman_glow, wingman_core)


func _draw_ship(offset: Vector2, scale: float, glow_color: Color, core_color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		offset + Vector2(0.0, -30.0 * scale),
		offset + Vector2(24.0 * scale, 20.0 * scale),
		offset + Vector2(-24.0 * scale, 20.0 * scale),
		offset + Vector2(0.0, -30.0 * scale)
	])

	for width in [18.0 * scale, 11.0 * scale]:
		draw_polyline(points, glow_color, width, true)

	draw_polyline(points, core_color, maxf(2.0, 3.0 * scale), true)
	draw_line(
		offset + Vector2(0.0, -30.0 * scale),
		offset + Vector2(0.0, 8.0 * scale),
		core_color,
		maxf(1.5, 2.0 * scale),
		true
	)
	draw_circle(offset, maxf(2.2, 3.0 * scale), Color(0.9, 1.0, 1.0, 0.95))
