@tool
class_name CanvasNode
extends CanvasElement

## A small fixed-size marker node (circle or triangle).
## Supports color changes, arrow connections, selection, and dragging.
## No text editing, no resize handles.
##
## Inherits from CanvasElement: selection state, drag lifecycle, grid snap,
## group membership ("clickable", "clickable_element"), and multi-drag signals.
##
## Unique behavior:
##   - handle_click override sets drag_mode body (no handles) and emits clicked.
##   - handle_double_click override returns true (no-op; nodes cannot edit text).
##   - Drawing: circle or triangle with selection-aware stroke.
##   - Collision: switches between CircleShape2D and ConvexPolygonShape2D.
##   - Anchors: 4 cardinal for circle, 3 vertex for triangle.
##   - Fixed size (no resize handles).
##   - No legend entry, no text editing.

enum ShapeMode { CIRCLE_NODE, TRIANGLE_NODE }

## Circle radius in world-space pixels.
const CIRCLE_RADIUS: float = 24.0

## Triangle vertices (local, inscribed in a bounding circle of 8px radius).
const TRIANGLE_VERTICES: PackedVector2Array = [
	Vector2(0.0, -24.0),  # top
	Vector2(-21.0, 12.0),  # bottom-left
	Vector2(21.0, 12.0),  # bottom-right
]

@export var shape_mode: ShapeMode = ShapeMode.CIRCLE_NODE

## Fill color; stroke is automatically adjusted for selection state.
@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value
		queue_redraw()

@onready var anchors: Node2D = $Anchors
@onready var select_area_2d: Area2D = $SelectArea2D


func _draw() -> void:
	var stroke_color: Color
	var stroke_width: float

	if is_selected:
		if is_primary:
			stroke_color = fill_color.lightened(0.4)
			stroke_width = 3.0
		else:
			stroke_color = fill_color.lightened(0.25)
			stroke_width = 2.5
	else:
		stroke_color = fill_color.darkened(0.4)
		stroke_width = 2.0

	match shape_mode:
		ShapeMode.CIRCLE_NODE:
			draw_circle(Vector2.ZERO, CIRCLE_RADIUS, fill_color)
			draw_circle(Vector2.ZERO, CIRCLE_RADIUS, stroke_color, false, stroke_width)
		ShapeMode.TRIANGLE_NODE:
			# Stroke: draw a slightly larger triangle for the outline
			var stroke_scale: float = 1.0 + (stroke_width / 5.0)
			var stroke_verts: PackedVector2Array = []

			for v: Vector2 in TRIANGLE_VERTICES:
				stroke_verts.append(v * stroke_scale)

			draw_colored_polygon(stroke_verts, stroke_color)

			# Fill
			draw_colored_polygon(TRIANGLE_VERTICES, fill_color)


## CanvasNode does not support text editing.
func supports_text_editing() -> bool:
	return false
