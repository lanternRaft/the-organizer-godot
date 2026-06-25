class_name CanvasNode
extends Node2D

## A small fixed-size marker node (circle or triangle).
## Supports color changes, arrow connections, selection, and dragging.
## No text editing, no resize handles.

signal clicked(input_event: InputEvent, node: Node)
signal anchor_changed()
signal multi_drag_moved(delta: Vector2)
signal multi_drag_ended()

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

## Whether this node is currently selected.
var is_selected: bool = false

## Whether this node is the primary (last-clicked) selection.
var is_primary: bool = false

## Drag mode: "body" or "" if idle.
var _drag_mode: String = ""

## World position where the current drag started.
var _drag_start_world: Vector2 = Vector2.ZERO

## Node position when the current drag started.
var _drag_start_position: Vector2 = Vector2.ZERO

## Cumulative delta from the previous frame, used to compute incremental delta.
var _last_delta: Vector2 = Vector2.ZERO

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

## Static tracking for bump resolution — prevents double-processing within one frame.
static var _bump_frame: int = -1
static var _bump_processed: Array = []

@onready var _area: Area2D = $Area2D
@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D


func _ready() -> void:
	add_to_group("clickable")
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


# ----- Selection interface ---------------------------------------------------

## Sets selection state and triggers visual update.
func set_selected(value: bool) -> void:
	is_selected = value
	if not value:
		is_primary = false
	queue_redraw()


# ----- Clickable interface (duck-typing) -------------------------------------

## Called by ClickHandler when a pointer-down hits this node's Area2D.
## Emits clicked signal for Main to handle selection.
func handle_click(event: Dictionary) -> bool:
	_drag_mode = "body"
	clicked.emit(event.get("original_event", InputEventMouseButton.new()), self)
	return true


## Double-click is a deliberate no-op (nodes have no text editing).
func handle_double_click(_event: Dictionary) -> bool:
	return true


## Called after handle_click or when an already-selected node is clicked.
## Returns true if the node is already selected (drag can begin).
func handle_drag_begin(event: Dictionary) -> bool:
	if not is_selected:
		return false
	_drag_start_world = event.get("world_pos", Vector2.ZERO)
	_drag_start_position = position
	_last_delta = Vector2.ZERO
	_drag_mode = "body"
	return true


## Called by ClickHandler on mouse move while drag is active.
func handle_drag_move(event: Dictionary) -> void:
	if _drag_mode != "body":
		return
	var world_pos: Vector2 = event.get("world_pos", Vector2.ZERO)
	var delta: Vector2 = world_pos - _drag_start_world
	var incremental: Vector2 = delta - _last_delta
	_last_delta = delta
	position = _drag_start_position + delta
	multi_drag_moved.emit(incremental)
	anchor_changed.emit()
	resolve_overlaps()


## Called by ClickHandler on pointer up while drag is active.
func handle_drag_end(_event: Dictionary) -> void:
	if _drag_mode == "body":
		position = position.snapped(Vector2(20.0, 20.0))
		anchor_changed.emit()
		multi_drag_ended.emit()
	_drag_mode = ""
	queue_redraw()


# ----- Anchor system ---------------------------------------------------------

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


# ----- Collision shape -------------------------------------------------------

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


## Returns the overlap radius used for bump resolution.
func overlap_radius() -> float:
	match sub_mode:
		"circle_node":
			return CIRCLE_RADIUS
		"triangle_node":
			return 8.0  # Inscribed circle radius approximates the triangle's bounding radius.
	return 8.0


# ----- Bump resolution -------------------------------------------------------

## Resolves overlaps between this node and other elements (LabelShape and CanvasNode).
## Uses the same pattern as LabelShape.resolve_overlaps().
func resolve_overlaps() -> void:
	var current_frame: int = Engine.get_process_frames()
	if current_frame != _bump_frame:
		_bump_frame = current_frame
		_bump_processed.clear()

	if self in _bump_processed:
		return
	_bump_processed.append(self)

	var current_round: Array[Node2D] = [self]
	var iteration: int = 0
	while iteration < 5 and not current_round.is_empty():
		iteration += 1

		var push_map: Dictionary = {}  # Node2D -> Vector2
		var next_round: Array[Node2D] = []

		for mover: Node2D in current_round:
			if not is_instance_valid(mover):
				continue
			# Use direct Area2D reference from the mover's scene structure.
			var mover_area: Area2D = null
			if mover is CanvasNode:
				mover_area = (mover as CanvasNode)._area
			elif mover is LabelShape:
				mover_area = (mover as LabelShape).get_node("Area2D") as Area2D

			if mover_area == null:
				continue

			var overlapping_areas: Array[Area2D] = mover_area.get_overlapping_areas()
			for area: Area2D in overlapping_areas:
				var parent: Node2D = area.get_parent() as Node2D
				if not (parent is LabelShape or parent is CanvasNode):
					continue
				if parent == mover or parent in _bump_processed:
					continue

				var push_vec: Vector2 = _compute_push_vector(mover, parent)
				if push_vec == Vector2.ZERO:
					continue

				if push_map.has(parent):
					push_map[parent] += push_vec
				else:
					push_map[parent] = push_vec
					next_round.append(parent)

		for other: Node2D in next_round:
			other.position += push_map[other]
			if other.has_signal("anchor_changed"):
				if other is LabelShape:
					(other as LabelShape).emit_signal("anchor_changed")
				elif other is CanvasNode:
					(other as CanvasNode).emit_signal("anchor_changed")
			_bump_processed.append(other)

		current_round = next_round


## Computes the push vector to move `other` away from `mover`.
## Works with LabelShape and CanvasNode.
static func _compute_push_vector(mover: Node2D, other: Node2D) -> Vector2:
	var radius_a: float = 8.0
	var radius_b: float = 8.0
	if mover.has_method("overlap_radius"):
		radius_a = mover.call("overlap_radius")
	if other.has_method("overlap_radius"):
		radius_b = other.call("overlap_radius")
	var center_a: Vector2 = mover.global_position
	var center_b: Vector2 = other.global_position
	var distance: float = center_a.distance_to(center_b)
	var min_dist: float = radius_a + radius_b

	if distance >= min_dist or distance < 0.001:
		return Vector2.ZERO

	var direction: Vector2 = (center_b - center_a) / distance
	var overlap: float = min_dist - distance
	return direction * overlap
