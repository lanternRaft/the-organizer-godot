class_name Arrow
extends Node2D

## Cubic bezier arrow connecting two LabelShape anchors.
## Renders a visible stroke, an invisible wider hit-line for click detection,
## and a mono-directional arrowhead at the end point.

signal selected(arrow: Arrow)

## Emitted during a multi-drag to broadcast the movement delta to Main
## so it can shift all other selected elements by the same amount.
## delta: raw movement offset in world-space pixels.
signal multi_drag_moved(delta: Vector2)

## Anchor reference data: shape paths are used instead of direct refs so that
## shape deletion doesn't leave dangling pointers.
var start_shape_path: NodePath
var end_shape_path: NodePath
var start_anchor_label: String  # "top", "bottom", "left", "right"
var end_anchor_label: String

var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()
		if vis_line != null:
			if value:
				vis_line.default_color = Color(0.6, 0.8, 1.0) if is_primary else Color(0.6, 0.8, 1.0, 0.7)
			else:
				vis_line.default_color = Color(1, 1, 1)

## Whether this arrow is the primary (last-clicked) selection.
## When true, uses stronger highlight. Otherwise uses dimmer highlight.
var is_primary: bool = false:
	set(value):
		is_primary = value
		queue_redraw()
		if vis_line != null:
			if is_selected:
				vis_line.default_color = Color(0.6, 0.8, 1.0) if value else Color(0.6, 0.8, 1.0, 0.7)
			else:
				vis_line.default_color = Color(1, 1, 1)

## Last-clicked world position for drag delta calculation.
var _drag_start_world: Vector2 = Vector2.ZERO

## Arrow position when the drag started.
var _drag_start_position: Vector2 = Vector2.ZERO

const ARROWHEAD_SIZE: float = 10.0
const ARROWHEAD_HALF_ANGLE: float = 0.4  # half-angle in radians (~23 degrees)

## Number of sample points for bezier approximation (affects smoothness).
const CURVE_SAMPLES: int = 40

## Cached bezier points used for hit-testing and arrowhead rendering.
var _cached_bezier_points: PackedVector2Array = PackedVector2Array()
var _cached_arrowhead_tip: Vector2 = Vector2.ZERO
var _cached_arrowhead_dir: Vector2 = Vector2.ZERO

@onready var vis_line: Line2D = $VisLine
@onready var hit_line: Line2D = $HitLine


func _ready() -> void:
	add_to_group("arrows")
	vis_line.default_color = Color(1, 1, 1)
	vis_line.width = 2.0
	vis_line.antialiased = true
	hit_line.width = 14.0
	hit_line.default_color = Color.TRANSPARENT
	hit_line.antialiased = true


func _draw() -> void:
	if _cached_bezier_points.is_empty():
		return

	# Draw arrowhead as a filled triangle at the end point.
	var tip: Vector2 = _cached_arrowhead_tip
	var dir: Vector2 = _cached_arrowhead_dir

	if dir.length_squared() < 0.0001:
		return  # Degenerate case

	var perp: Vector2 = dir.rotated(PI / 2.0).normalized()
	var half_size: float = ARROWHEAD_SIZE
	var half_width: float = half_size * tan(ARROWHEAD_HALF_ANGLE)

	var base_left: Vector2 = tip - dir * half_size - perp * half_width
	var base_right: Vector2 = tip - dir * half_size + perp * half_width

	var arrowhead_color: Color = vis_line.default_color
	draw_colored_polygon(PackedVector2Array([tip, base_left, base_right]), arrowhead_color)


## Rebuilds the bezier path from the connected shapes' current anchor positions.
## Must be called after either shape moves or resizes.
func rebuild_path() -> void:
	var start_shape: Node = _resolve_shape(start_shape_path)
	var end_shape: Node = _resolve_shape(end_shape_path)

	if start_shape == null or end_shape == null:
		# One of the connected shapes was deleted; queue free.
		queue_free()
		return

	var p0: Vector2 = get_anchor_edge_position_static(start_shape, start_anchor_label)
	var p3: Vector2 = get_anchor_edge_position_static(end_shape, end_anchor_label)

	var outward_start: Vector2 = get_anchor_outward_normal_static(start_anchor_label)
	var outward_end: Vector2 = get_anchor_outward_normal_static(end_anchor_label)

	var segment_len: float = p0.distance_to(p3)
	var reach: float = clampf(segment_len * 0.35, 30.0, 100.0)

	var p1: Vector2 = p0 + outward_start * reach
	var p2: Vector2 = p3 + outward_end * reach

	# Sample the cubic bezier.
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(CURVE_SAMPLES)
	for i: int in CURVE_SAMPLES:
		var t: float = float(i) / (CURVE_SAMPLES - 1)
		points[i] = _cubic_bezier(p0, p1, p2, p3, t)

	_cached_bezier_points = points
	_cached_arrowhead_tip = p3
	_cached_arrowhead_dir = (p3 - p2).normalized()
	if _cached_arrowhead_dir.length_squared() < 0.0001:
		_cached_arrowhead_dir = (p3 - p0).normalized()

	vis_line.points = points
	hit_line.points = points
	queue_redraw()


## Returns the start shape node resolved from the stored NodePath.
func get_start_shape() -> Node:
	return _resolve_shape(start_shape_path)


## Returns the end shape node resolved from the stored NodePath.
func get_end_shape() -> Node:
	return _resolve_shape(end_shape_path)


## Iterates arrows managed by ArrowManager that are connected to the given shape
## and calls rebuild_path on them.
static func rebuild_arrows_for_shape(shape: Node, all_arrows: Array) -> void:
	for arrow: Node in all_arrows:
		if not is_instance_valid(arrow):
			continue
		var a: Arrow = arrow as Arrow
		if a == null:
			continue
		var start_shape: Node = a._resolve_shape(a.start_shape_path)
		var end_shape: Node = a._resolve_shape(a.end_shape_path)
		if start_shape == shape or end_shape == shape:
			a.rebuild_path()


# ----- private helpers -------------------------------------------------------

## Unified setter called by Main during selection state changes.
## Matches the LabelShape API so both types can be treated uniformly.
func set_selected(value: bool) -> void:
	self.is_selected = value


## Called by ClickHandler to determine if a drag should begin on this element.
## Returns true if the arrow is selected (allows multi-drag from any selected element).
func handle_drag_begin(event: Dictionary) -> bool:
	if not is_selected:
		return false
	_drag_start_world = event.get("world_pos", Vector2.ZERO)
	_drag_start_position = position
	return true


## Called by ClickHandler on each mouse move while drag is active.
## Moves the arrow by the world-space delta, then broadcasts delta to Main
## so other selected elements also move.
func handle_drag_move(event: Dictionary) -> void:
	var world_pos: Vector2 = event.get("world_pos", Vector2.ZERO)
	var delta: Vector2 = world_pos - _drag_start_world
	position = _drag_start_position + delta
	queue_redraw()
	multi_drag_moved.emit(delta)


## Called by ClickHandler on pointer up to end the drag.
## Snaps position to 20px grid.
func handle_drag_end(_event: Dictionary) -> void:
	position = position.snapped(Vector2(20.0, 20.0))


## Static utility: returns the edge position (on the ellipse boundary) for an anchor label.
static func get_anchor_edge_position_static(shape: Node, label: String) -> Vector2:
	var rx: float = shape.get("rx")
	var ry: float = shape.get("ry")
	var local_pos: Vector2
	match label:
		"top": local_pos = Vector2(0, -ry)
		"bottom": local_pos = Vector2(0, ry)
		"left": local_pos = Vector2(-rx, 0)
		"right": local_pos = Vector2(rx, 0)
		_:
			local_pos = Vector2.ZERO
	var shape_2d: Node2D = shape as Node2D
	if shape_2d != null:
		return shape_2d.to_global(local_pos)
	return local_pos


## Static utility: returns the outward normal for an anchor label.
static func get_anchor_outward_normal_static(label: String) -> Vector2:
	match label:
		"top": return Vector2(0, -1)
		"bottom": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
	return Vector2.ZERO


func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	var ut: float = u * t
	return u * u * u * p0 + 3.0 * u * ut * p1 + 3.0 * t * ut * p2 + t * t * t * p3


func _resolve_shape(path: NodePath) -> Node:
	if path.is_empty():
		return null
	var shape: Node = get_node_or_null(path)
	if not is_instance_valid(shape):
		return null
	return shape