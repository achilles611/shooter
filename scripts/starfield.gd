extends Node2D

const SCREEN_SIZE := Vector2(1920, 1080)

@export var star_count: int = 110
@export var speed_min: float = 24.0
@export var speed_max: float = 82.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var stars: Array[Dictionary] = []


func _ready() -> void:
	rng.randomize()
	_build_starfield()


func _process(delta: float) -> void:
	for star in stars:
		var position: Vector2 = star["position"]
		position.y += star["speed"] * delta

		if position.y - star["trail"] > SCREEN_SIZE.y:
			position.y = -rng.randf_range(10.0, SCREEN_SIZE.y * 0.35)
			position.x = rng.randf_range(0.0, SCREEN_SIZE.x)

		star["position"] = position

	queue_redraw()


func _draw() -> void:
	for star in stars:
		var head: Vector2 = star["position"]
		var tail: Vector2 = head - Vector2(0.0, float(star["trail"]))
		var color: Color = Color(0.7, 0.82, 1.0, float(star["alpha"]))
		draw_line(tail, head, color, float(star["size"]), true)
		draw_circle(head, maxf(float(star["size"]) * 0.4, 0.8), Color(0.95, 1.0, 1.0, minf(float(star["alpha"]) + 0.15, 1.0)))


func _build_starfield() -> void:
	stars.clear()

	for _i in star_count:
		stars.append({
			"position": Vector2(
				rng.randf_range(0.0, SCREEN_SIZE.x),
				rng.randf_range(0.0, SCREEN_SIZE.y)
			),
			"speed": rng.randf_range(speed_min, speed_max),
			"trail": rng.randf_range(8.0, 28.0),
			"size": rng.randf_range(1.0, 2.2),
			"alpha": rng.randf_range(0.2, 0.65),
		})
