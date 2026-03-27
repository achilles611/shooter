extends Control

signal retry_requested
signal quit_requested

const SCREEN_SIZE := Vector2(1920.0, 1080.0)

var max_hearts: int = 3
var current_hearts: int = 3
var score: int = 0
var flash_timer: float = 0.0
var flash_duration: float = 0.0

var score_label: Label
var flash_label: Label
var game_over_panel: Panel
var retry_button: Button
var quit_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_create_score_label()
	_create_flash_label()
	_create_game_over_panel()
	_update_score_text()
	queue_redraw()


func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer = maxf(flash_timer - delta, 0.0)
		flash_label.visible = flash_timer > 0.0
		flash_label.modulate.a = 0.45 + absf(sin((flash_duration - flash_timer) * 7.5)) * 0.55

		if flash_timer <= 0.0:
			flash_label.visible = false


func reset_hud(new_max_hearts: int, new_score: int) -> void:
	max_hearts = new_max_hearts
	current_hearts = new_max_hearts
	score = new_score
	flash_timer = 0.0
	flash_duration = 0.0
	flash_label.visible = false
	hide_game_over()
	_update_score_text()
	queue_redraw()


func set_hearts(value: int) -> void:
	current_hearts = maxi(value, 0)
	queue_redraw()


func set_score(value: int) -> void:
	score = value
	_update_score_text()


func show_flash_message(message: String, duration: float) -> void:
	flash_duration = duration
	flash_timer = duration
	flash_label.text = message
	flash_label.visible = true
	flash_label.modulate = Color(0.45, 1.0, 0.55, 1.0)


func show_game_over() -> void:
	game_over_panel.visible = true


func hide_game_over() -> void:
	game_over_panel.visible = false


func _draw() -> void:
	var base_position: Vector2 = Vector2(52.0, SCREEN_SIZE.y - 72.0)

	for heart_index in max_hearts:
		var heart_center: Vector2 = base_position + Vector2(54.0 * heart_index, 0.0)
		var is_filled: bool = heart_index < current_hearts
		_draw_heart(heart_center, 18.0, is_filled)


func _draw_heart(center: Vector2, size: float, filled: bool) -> void:
	var heart_points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, size),
		center + Vector2(size * 0.95, size * 0.15),
		center + Vector2(size * 0.9, -size * 0.55),
		center + Vector2(size * 0.35, -size * 0.95),
		center + Vector2(0.0, -size * 0.55),
		center + Vector2(-size * 0.35, -size * 0.95),
		center + Vector2(-size * 0.9, -size * 0.55),
		center + Vector2(-size * 0.95, size * 0.15),
		center + Vector2(0.0, size),
	])
	var fill_color: Color = Color(0.9, 0.15, 0.15, 1.0) if filled else Color(1.0, 1.0, 1.0, 1.0)
	var outline_color: Color = Color(0.0, 0.0, 0.0, 1.0)

	draw_colored_polygon(heart_points, fill_color)
	draw_polyline(heart_points, outline_color, 3.0, true)


func _create_score_label() -> void:
	score_label = Label.new()
	score_label.position = Vector2(220.0, SCREEN_SIZE.y - 88.0)
	score_label.size = Vector2(360.0, 48.0)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color(0.92, 1.0, 0.96, 1.0))
	add_child(score_label)


func _create_flash_label() -> void:
	flash_label = Label.new()
	flash_label.size = Vector2(1720.0, 260.0)
	flash_label.position = Vector2((SCREEN_SIZE.x - flash_label.size.x) * 0.5, 88.0)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	flash_label.add_theme_font_size_override("font_size", 112)
	flash_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55, 1.0))
	flash_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.28, 0.04, 0.95))
	flash_label.add_theme_constant_override("shadow_offset_x", 4)
	flash_label.add_theme_constant_override("shadow_offset_y", 4)

	var script_font: SystemFont = SystemFont.new()
	script_font.font_names = PackedStringArray([
		"Old English Text MT",
		"Lucida Calligraphy",
		"Gabriola",
		"Georgia",
	])
	flash_label.add_theme_font_override("font", script_font)
	flash_label.visible = false
	add_child(flash_label)


func _create_game_over_panel() -> void:
	game_over_panel = Panel.new()
	game_over_panel.visible = false
	game_over_panel.position = Vector2(640.0, 270.0)
	game_over_panel.size = Vector2(640.0, 420.0)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 0.96)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(game_over_panel)

	var title: Label = Label.new()
	title.text = "GAME OVER"
	title.position = Vector2(120.0, 70.0)
	title.size = Vector2(400.0, 80.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	game_over_panel.add_child(title)

	retry_button = Button.new()
	retry_button.text = "Try Again"
	retry_button.position = Vector2(200.0, 190.0)
	retry_button.size = Vector2(240.0, 58.0)
	retry_button.pressed.connect(_on_retry_pressed)
	game_over_panel.add_child(retry_button)

	quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.position = Vector2(200.0, 272.0)
	quit_button.size = Vector2(240.0, 58.0)
	quit_button.pressed.connect(_on_quit_pressed)
	game_over_panel.add_child(quit_button)


func _update_score_text() -> void:
	if score_label != null:
		score_label.text = "Score: %d" % score


func _on_retry_pressed() -> void:
	retry_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()
