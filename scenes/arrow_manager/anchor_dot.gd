extends Node2D

## Simple circular dot node used for anchor markers on shapes.
## Draws itself in _draw() based on meta properties set by ArrowManager.

func _draw() -> void:
	var radius: float = get_meta("dot_radius", 4.0)
	var fill: Color = get_meta("dot_fill", Color(1, 1, 1))
	var stroke: Color = get_meta("dot_stroke", Color(0.23, 0.51, 0.965))

	draw_circle(Vector2.ZERO, radius, fill)
	draw_circle(Vector2.ZERO, radius, stroke, false, 1.5)