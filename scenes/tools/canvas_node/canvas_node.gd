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

enum SHAPE_MODE { CIRCLE_NODE, TRIANGLE_NODE }

@export var shape_mode: SHAPE_MODE = SHAPE_MODE.CIRCLE_NODE

## Fill color; stroke is automatically adjusted for selection state.
@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value
		queue_redraw()

## Circle radius in world-space pixels.
const CIRCLE_RADIUS: float = 8.0

## Triangle vertices (local, inscribed in a bounding circle of 8px radius).
const TRIANGLE_VERTICES: PackedVector2Array = [
	Vector2(0.0, -8.0),  # top
	Vector2(-7.0, 4.0),  # bottom-left
	Vector2(7.0, 4.0),  # bottom-right
]

## Anchor labels for each sub-mode.
const CIRCLE_ANCHOR_LABELS: Array[String] = ["top", "bottom", "left", "right"]
const TRIANGLE_ANCHOR_LABELS: Array[String] = ["top", "bottom_left", "bottom_right"]

## Anchor positions (local) for each anchor label.
const ANCHOR_POSITIONS: Dictionary = {
	"top": Vector2(0.0, -8.0),
	"bottom": Vector2(0.0, 8.0),
	"left": Vector2(-8.0, 0.0),
	"right": Vector2(8.0, 0.0),
	"bottom_left": Vector2(-7.0, 4.0),
	"bottom_right": Vector2(7.0, 4.0),
}


@onready var _collision_shape: CollisionShape2D = $SelectArea2D/CollisionShape2D
@onready var anchors: Node2D = $Anchors
@onready var select_area_2d: Area2D = $SelectArea2D


func _ready() -> void:
	super._ready()
	_update_collision_shape()


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
		SHAPE_MODE.CIRCLE_NODE:
			draw_circle(Vector2.ZERO, CIRCLE_RADIUS, fill_color)
			draw_circle(Vector2.ZERO, CIRCLE_RADIUS, stroke_color, false, stroke_width)
		SHAPE_MODE.TRIANGLE_NODE:
			# Fill
			draw_colored_polygon(TRIANGLE_VERTICES, fill_color)
			# Stroke: draw each edge as a line
			var verts: PackedVector2Array = TRIANGLE_VERTICES
			var closed: bool = true
			for i: int in 3:
				var a: Vector2 = verts[i]
				var b: Vector2 = verts[(i + 1) % 3] if closed else verts[i + 1]
				if i == 2 and not closed:
					break
				draw_line(a, b, stroke_color, stroke_width)
			# Close the last edge back to the first
			draw_line(verts[2], verts[0], stroke_color, stroke_width)


# ----- Clickable Interface (overrides) --------------------------------------

#
### Called by ClickHandler when a pointer-down hits this node's Area2D.
### Sets drag mode to "body" (no resize handles) and emits clicked signal.
#func handle_click(event: Dictionary) -> bool:
	#dragging = true
	#clicked.emit(event.get("original_event", InputEventMouseButton.new()), self)
	#return true
#
#
### Double-click is a deliberate no-op (nodes have no text editing).
#func handle_double_click(_event: Dictionary) -> bool:
	#return true


# ----- Virtual Properties ----------------------------------------------------


## CanvasNode does not support text editing.
func supports_text_editing() -> bool:
	return false


## CanvasNode does not appear in the legend panel.
func shows_in_legend() -> bool:
	return false


# ----- Collision Shape -------------------------------------------------------


func _update_collision_shape() -> void:
	if not is_node_ready():
		return
	match shape_mode:
		SHAPE_MODE.CIRCLE_NODE:
			var circle_shape: CircleShape2D = CircleShape2D.new()
			circle_shape.radius = CIRCLE_RADIUS
			_collision_shape.shape = circle_shape
		SHAPE_MODE.TRIANGLE_NODE:
			var poly_shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
			poly_shape.points = TRIANGLE_VERTICES
			_collision_shape.shape = poly_shape

# Show the line anchors
func show_anchors() -> void:
	anchors.show()

# Show the line anchors
func hide_anchors() -> void:
	anchors.hide()
