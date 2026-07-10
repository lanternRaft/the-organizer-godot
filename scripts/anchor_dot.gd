## Simple circular dot node used for anchor markers on shapes.
## Draws itself in _draw() based on meta properties set by ArrowManager.
@tool
extends Node2D

@export var draw_outline: bool = true
@export var radius: float = 4.0
@export var fill: Color = Color(1, 1, 1)
@export var outline: Color =  Color(0.23, 0.51, 0.965)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill)
	
	if draw_outline:
		draw_circle(Vector2.ZERO, radius, outline, false, 1.5)
