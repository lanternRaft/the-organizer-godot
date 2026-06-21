extends Node2D

## Oval shape rendered via custom drawing (ellipse fill + stroke).
## No Area2D — click hit-testing will be added later with selection.

@export var rx: float = 40.0:
	set(value):
		rx = value
		queue_redraw()

@export var ry: float = 25.0:
	set(value):
		ry = value
		queue_redraw()

@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value
		queue_redraw()


func _ready() -> void:
	modulate.a = 0.9


func _draw() -> void:
	## Stroke color: 40% darker than fill
	var stroke_color: Color = fill_color.darkened(0.4)

	## Fill ellipse (center, major, minor, color)
	draw_ellipse(Vector2.ZERO, rx, ry, fill_color)

	## Stroke outline (unfilled, width = 2.0)
	draw_ellipse(Vector2.ZERO, rx, ry, stroke_color, false, 2.0)
