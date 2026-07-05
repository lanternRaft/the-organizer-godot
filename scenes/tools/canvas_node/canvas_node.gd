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

## "circle_node" or "triangle_node". Setter triggers redraw and collision shape update.
@export var sub_mode: String = "circle_node":
	set(value):
		if value == sub_mode:
			return
		sub_mode = value
		queue_redraw()
		_update_collision_shape()

## Fill color; stroke is automatically adjusted for selection state.
@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value
		queue_redraw()

## Circle radius in world-space pixels.
const CIRCLE_RADIUS: float = 8.0

## Triangle vertices (local, inscribed in a bounding circle of 8px radius).
const TRIANGLE_VERTICES: PackedVector2Array = [
	Vector2(0.0, -8.0),   # top
	Vector2(-7.0, 4.0),   # bottom-left
	Vector2(7.0, 4.0),    # bottom-right
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

@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D


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

	match sub_mode:
		"circle_node":
			draw_circle(Vector2.ZERO, CIRCLE_RADIUS, fill_color)
			draw_circle(Vector2.ZERO, CIRCLE_RADIUS, stroke_color, false, stroke_width)
		"triangle_node":
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

## Called by ClickHandler when a pointer-down hits this node's Area2D.
## Sets drag mode to "body" (no resize handles) and emits clicked signal.
func handle_click(event: Dictionary) -> bool:
	_drag_mode = "body"
	clicked.emit(event.get("original_event", InputEventMouseButton.new()), self)
	return true


## Double-click is a deliberate no-op (nodes have no text editing).
func handle_double_click(_event: Dictionary) -> bool:
	return true


# ----- Anchor System ---------------------------------------------------------

## Returns the list of anchor labels for this node's current sub-mode.
func get_anchor_points() -> Array[String]:
	match sub_mode:
		"circle_node":
			return CIRCLE_ANCHOR_LABELS
		"triangle_node":
			return TRIANGLE_ANCHOR_LABELS
	return []


## Returns the global position of the given anchor label.
func get_anchor_position(label: String) -> Vector2:
	var local_pos: Vector2 = ANCHOR_POSITIONS.get(label, Vector2.ZERO)
	return to_global(local_pos)


## Returns anchor definitions as an Array of Dictionaries with "label" and "offset" keys.
## Overrides the base class virtual method.
func get_anchor_positions() -> Array[Dictionary]:
	var labels: Array[String] = get_anchor_points()
	var result: Array[Dictionary] = []
	for label: String in labels:
		result.append({
			"label": label,
			"offset": ANCHOR_POSITIONS.get(label, Vector2.ZERO)
		})
	return result


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
	match sub_mode:
		"circle_node":
			var circle_shape: CircleShape2D = CircleShape2D.new()
			circle_shape.radius = CIRCLE_RADIUS
			_collision_shape.shape = circle_shape
		"triangle_node":
			var poly_shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
			poly_shape.points = TRIANGLE_VERTICES
			_collision_shape.shape = poly_shape
