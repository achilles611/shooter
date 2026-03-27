extends Node2D

const SCREEN_SIZE := Vector2(1920.0, 1080.0)

@export var speed: float = 1100.0
@export var hit_radius: float = 12.0

var direction: Vector2 = Vector2.UP


func configure(spawn_direction: Vector2) -> void:
	direction = spawn_direction.normalized()
	rotation = direction.angle() + PI * 0.5


func advance(delta: float) -> void:
	position += direction * speed * delta

	if (
		global_position.x < -60.0
		or global_position.x > SCREEN_SIZE.x + 60.0
		or global_position.y < -60.0
		or global_position.y > SCREEN_SIZE.y + 60.0
	):
		queue_free()


func _draw() -> void:
	var glow: Color = Color(0.35, 0.9, 1.0, 0.18)
	var core: Color = Color(0.85, 0.98, 1.0, 0.95)
	draw_line(Vector2.ZERO, Vector2(0.0, -34.0), glow, 12.0, true)
	draw_line(Vector2.ZERO, Vector2(0.0, -34.0), core, 3.0, true)
