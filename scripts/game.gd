extends Node2D

const SCREEN_SIZE := Vector2(1920, 1080)
const PLAYER_START_POSITION := Vector2(960, 972)
const ENEMY_COLUMNS := 9
const ENEMY_ROWS := 9
const ENEMY_SPACING := Vector2(96, 82)
const FORMATION_EDGE_PADDING := 72.0
const LEVEL_ONE_DROP_CHANCE := 0.02
const LEVEL_TWO_DROP_CHANCE := 0.05
const LEVEL_ONE_POINTS := 2
const LEVEL_TWO_POINTS := 5
const LEVEL_THREE_POINTS := 50
const LEVEL_CLEAR_MESSAGE_DURATION := 2.8
const PLAYER_MAX_HEARTS := 3

const EnemyScene = preload("res://scripts/enemy.gd")
const GreenEnemyScene = preload("res://scripts/green_enemy.gd")
const MetatronBossScene = preload("res://scripts/metatron_boss.gd")
const LaserScene = preload("res://scripts/laser.gd")
const ExplosionScene = preload("res://scripts/explosion.gd")
const PowerupScene = preload("res://scripts/powerup.gd")

@onready var enemy_formation: Node2D = $EnemyFormation
@onready var lasers: Node2D = $Lasers
@onready var powerups: Node2D = $Powerups
@onready var effects: Node2D = $Effects
@onready var player = $Player
@onready var hud = $HUD

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_level: int = 1
var enemy_direction: float = 1.0
var enemy_horizontal_speed: float = 110.0
var enemy_drop_distance: float = 34.0
var score: int = 0
var player_hearts: int = PLAYER_MAX_HEARTS
var player_invulnerability_timer: float = 0.0
var awaiting_level_two: bool = false
var awaiting_level_three: bool = false
var level_transition_timer: float = 0.0
var is_game_over: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	rng.randomize()
	player.shots_fired.connect(_on_player_shots_fired)
	hud.retry_requested.connect(_on_retry_requested)
	hud.quit_requested.connect(_on_quit_requested)
	_start_new_game()


func _process(delta: float) -> void:
	player_invulnerability_timer = maxf(player_invulnerability_timer - delta, 0.0)
	_update_lasers(delta)
	_update_powerups(delta)

	if is_game_over:
		return

	if awaiting_level_two:
		level_transition_timer = maxf(level_transition_timer - delta, 0.0)
		if level_transition_timer <= 0.0:
			awaiting_level_two = false
			_begin_level_two()
		return
	elif awaiting_level_three:
		level_transition_timer = maxf(level_transition_timer - delta, 0.0)
		if level_transition_timer <= 0.0:
			awaiting_level_three = false
			_begin_level_three()
		return

	if current_level == 1:
		_update_level_one_enemies(delta)
	elif current_level == 2:
		_update_level_two_enemies(delta)
	else:
		_update_level_three_boss(delta)

	_handle_collisions()
	_handle_powerup_pickups()
	_handle_enemy_player_collisions()
	_handle_level_progression(delta)


func _start_new_game() -> void:
	is_game_over = false
	awaiting_level_two = false
	awaiting_level_three = false
	level_transition_timer = 0.0
	current_level = 1
	score = 0
	player_hearts = PLAYER_MAX_HEARTS
	player_invulnerability_timer = 0.0
	player.position = PLAYER_START_POSITION
	player.reset_state()
	player.set_active(true)
	hud.reset_hud(PLAYER_MAX_HEARTS, score)
	_clear_runtime_nodes()
	_spawn_level_one_wave()


func _clear_runtime_nodes() -> void:
	_free_children(enemy_formation)
	_free_children(lasers)
	_free_children(powerups)
	_free_children(effects)


func _free_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()


func _spawn_level_one_wave() -> void:
	current_level = 1
	enemy_direction = 1.0
	enemy_horizontal_speed = 110.0
	enemy_drop_distance = 34.0
	enemy_formation.position = Vector2(SCREEN_SIZE.x * 0.5, 108.0)

	var formation_width: float = float(ENEMY_COLUMNS - 1) * ENEMY_SPACING.x
	var start: Vector2 = Vector2(-formation_width * 0.5, 0.0)

	for row in ENEMY_ROWS:
		for column in ENEMY_COLUMNS:
			var enemy = EnemyScene.new()
			enemy.position = start + Vector2(column * ENEMY_SPACING.x, row * ENEMY_SPACING.y)
			enemy.point_value = LEVEL_ONE_POINTS
			enemy.drop_chance = LEVEL_ONE_DROP_CHANCE
			enemy_formation.add_child(enemy)


func _begin_level_two() -> void:
	current_level = 2
	_spawn_level_two_wave()


func _begin_level_three() -> void:
	current_level = 3
	_spawn_level_three_boss()


func _spawn_level_two_wave() -> void:
	enemy_formation.position = Vector2.ZERO

	for child in enemy_formation.get_children():
		child.free()

	for enemy_index in 8:
		var enemy = GreenEnemyScene.new()
		var start_position: Vector2 = Vector2(170.0 + float(enemy_index) * 200.0, 150.0 + float(enemy_index % 2) * 95.0)
		var direction: float = -1.0 if enemy_index % 2 == 0 else 1.0
		enemy.setup(start_position, direction, float(enemy_index) * 0.55)
		enemy.drop_chance = LEVEL_TWO_DROP_CHANCE
		enemy.point_value = LEVEL_TWO_POINTS
		enemy_formation.add_child(enemy)


func _spawn_level_three_boss() -> void:
	enemy_formation.position = Vector2.ZERO

	for child in enemy_formation.get_children():
		child.free()

	var boss = MetatronBossScene.new()
	boss.position = Vector2(SCREEN_SIZE.x * 0.5, 210.0)
	boss.point_value = LEVEL_THREE_POINTS
	enemy_formation.add_child(boss)


func _update_level_one_enemies(delta: float) -> void:
	if enemy_formation.get_child_count() == 0:
		return

	var edges: Vector2 = _get_enemy_edges()
	enemy_formation.position.x += enemy_direction * enemy_horizontal_speed * delta

	var left_world: float = enemy_formation.position.x + edges.x
	var right_world: float = enemy_formation.position.x + edges.y

	if enemy_direction > 0.0 and right_world >= SCREEN_SIZE.x - FORMATION_EDGE_PADDING:
		enemy_direction = -1.0
		enemy_formation.position.x = SCREEN_SIZE.x - FORMATION_EDGE_PADDING - edges.y
		enemy_formation.position.y += enemy_drop_distance
	elif enemy_direction < 0.0 and left_world <= FORMATION_EDGE_PADDING:
		enemy_direction = 1.0
		enemy_formation.position.x = FORMATION_EDGE_PADDING - edges.x
		enemy_formation.position.y += enemy_drop_distance


func _update_level_two_enemies(delta: float) -> void:
	for enemy in enemy_formation.get_children():
		enemy.advance(delta, player.global_position)


func _update_level_three_boss(delta: float) -> void:
	for boss in enemy_formation.get_children():
		boss.advance(delta, player.global_position)


func _update_lasers(delta: float) -> void:
	for laser in lasers.get_children():
		laser.advance(delta)


func _update_powerups(delta: float) -> void:
	for powerup in powerups.get_children():
		powerup.advance(delta)


func _handle_collisions() -> void:
	var dead_lasers: Array[Node] = []
	var dead_enemies: Array[Node] = []

	for laser in lasers.get_children():
		if not is_instance_valid(laser) or laser in dead_lasers:
			continue

		for enemy in enemy_formation.get_children():
			if not is_instance_valid(enemy) or enemy in dead_enemies:
				continue

			var hit_distance: float = float(laser.hit_radius) + float(enemy.radius)
			if laser.global_position.distance_to(enemy.global_position) <= hit_distance:
				dead_lasers.append(laser)
				if enemy.has_method("take_hit"):
					var defeated: bool = enemy.take_hit()
					if defeated:
						dead_enemies.append(enemy)
						_destroy_enemy(enemy)
					else:
						_spawn_explosion(laser.global_position)
				else:
					dead_enemies.append(enemy)
					_destroy_enemy(enemy)
				break

	for laser in dead_lasers:
		if is_instance_valid(laser):
			laser.queue_free()


func _handle_powerup_pickups() -> void:
	var collected_powerups: Array[Node] = []
	var player_pickup_radius: float = float(player.pickup_radius)

	for powerup in powerups.get_children():
		if not is_instance_valid(powerup):
			continue

		var collect_distance: float = float(powerup.pickup_radius) + player_pickup_radius
		if powerup.global_position.distance_to(player.global_position) <= collect_distance:
			collected_powerups.append(powerup)
			player.apply_powerup(powerup.powerup_type)

	for powerup in collected_powerups:
		if is_instance_valid(powerup):
			powerup.queue_free()


func _handle_enemy_player_collisions() -> void:
	if player_invulnerability_timer > 0.0:
		return

	var player_hit_radius: float = float(player.hit_radius)

	for enemy in enemy_formation.get_children():
		if not is_instance_valid(enemy):
			continue

		var hit_distance: float = player_hit_radius + float(enemy.radius)
		if enemy.global_position.distance_to(player.global_position) <= hit_distance:
			_spawn_explosion(enemy.global_position)
			enemy.queue_free()
			_apply_player_damage()
			break

	for boss in enemy_formation.get_children():
		if not is_instance_valid(boss) or not boss.has_method("is_beam_active"):
			continue

		if boss.is_beam_active():
			var beam_origin: Vector2 = boss.get_beam_origin()
			var beam_end: Vector2 = beam_origin + boss.get_beam_direction() * 2400.0
			var beam_half_width: float = float(boss.beam_width) * 0.5
			if _distance_to_segment(player.global_position, beam_origin, beam_end) <= beam_half_width:
				_apply_player_damage()
				break


func _handle_level_progression(delta: float) -> void:
	if enemy_formation.get_child_count() > 0:
		return

	if current_level == 1:
		awaiting_level_two = true
		level_transition_timer = LEVEL_CLEAR_MESSAGE_DURATION
		hud.show_flash_message("Good Job Shyshy!", LEVEL_CLEAR_MESSAGE_DURATION)
	elif current_level == 2:
		awaiting_level_three = true
		level_transition_timer = 2.2
		hud.show_flash_message("Level 3", 2.2)


func _apply_player_damage() -> void:
	player_hearts -= 1
	player_invulnerability_timer = 0.85
	hud.set_hearts(player_hearts)

	if player_hearts < 1:
		_trigger_game_over()


func _trigger_game_over() -> void:
	is_game_over = true
	player.set_active(false)
	hud.show_game_over()


func _destroy_enemy(enemy: Node) -> void:
	_spawn_explosion(enemy.global_position)
	_add_score(int(enemy.point_value))
	_try_spawn_powerup(enemy.global_position, float(enemy.drop_chance))
	enemy.queue_free()


func _add_score(points: int) -> void:
	score += points
	hud.set_score(score)


func _get_enemy_edges() -> Vector2:
	var left: float = INF
	var right: float = -INF

	for enemy in enemy_formation.get_children():
		var enemy_radius: float = float(enemy.radius)
		left = minf(left, enemy.position.x - enemy_radius)
		right = maxf(right, enemy.position.x + enemy_radius)

	return Vector2(left, right)


func _spawn_explosion(at_position: Vector2) -> void:
	var explosion = ExplosionScene.new()
	effects.add_child(explosion)
	explosion.global_position = at_position


func _try_spawn_powerup(at_position: Vector2, drop_chance: float) -> void:
	if rng.randf() > drop_chance:
		return

	var powerup = PowerupScene.new()
	powerups.add_child(powerup)
	powerup.global_position = at_position
	powerup.powerup_type = _roll_powerup_type()
	powerup.queue_redraw()


func _roll_powerup_type() -> StringName:
	if rng.randf() < 0.5:
		return &"spread"
	return &"wingman"


func _on_player_shots_fired(shots: Array) -> void:
	for shot_data in shots:
		var origin: Vector2 = shot_data["origin"]
		var shot_direction: Vector2 = shot_data["direction"]
		_spawn_laser(origin, shot_direction)


func _spawn_laser(at_position: Vector2, direction: Vector2) -> void:
	var laser = LaserScene.new()
	lasers.add_child(laser)
	laser.global_position = at_position
	laser.configure(direction)


func _on_retry_requested() -> void:
	_start_new_game()


func _on_quit_requested() -> void:
	get_tree().quit()


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment: Vector2 = segment_end - segment_start
	var segment_length_squared: float = segment.length_squared()

	if segment_length_squared <= 0.001:
		return point.distance_to(segment_start)

	var t: float = clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var projection: Vector2 = segment_start + segment * t
	return point.distance_to(projection)
