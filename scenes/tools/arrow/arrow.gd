class_name Arrow

extends Node2D

## Cubic bezier arrow connecting two CanvasElement anchors.
## Renders a visible stroke, an invisible wider hit-line for click detection,
## and a mono-directional arrowhead at the end point.
##
## Can also operate in "preview" mode (is_preview = true) for arrow drag
## previews. In preview mode, the arrow is configured with only a start anchor
## and the endpoint is updated dynamically via update_preview(). The arrowhead
## is suppressed in preview mode.

signal selected(arrow: Arrow)

## Emitted during a multi-drag to broadcast the movement delta to Main
## so it can shift all other selected elements by the same amount.
## delta: raw movement offset in world-space pixels.
signal multi_drag_moved(delta: Vector2)

const ARROWHEAD_SIZE: float = 10.0

const ARROWHEAD_HALF_ANGLE: float = 0.4  # half-angle in radians (~23 degrees)

## Number of sample points for bezier approximation (affects smoothness).
const CURVE_SAMPLES: int = 40

## Number of sample points for preview bezier (fewer for performance during drag).
const PREVIEW_SAMPLES: int = 20

## Anchor reference data: shape paths are used instead of direct refs so that
## shape deletion doesn't leave dangling pointers.
var start_shape_path: NodePath

var end_shape_path: NodePath

var start_anchor: LineAnchor

var end_anchor: LineAnchor

## When true, this arrow is a drag preview (no arrowhead drawn, dynamic endpoint).
var is_preview: bool = false

var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()
		if vis_line != null:
			if value:
				vis_line.default_color = (
					Color(0.6, 0.8, 1.0) if is_primary else Color(0.6, 0.8, 1.0, 0.7)
				)
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
				vis_line.default_color = (
					Color(0.6, 0.8, 1.0) if value else Color(0.6, 0.8, 1.0, 0.7)
				)
			else:
				vis_line.default_color = Color(1, 1, 1)

## Last-clicked world position for drag delta calculation.
var _drag_start_world: Vector2 = Vector2.ZERO

## Arrow position when the drag started.
var _drag_start_position: Vector2 = Vector2.ZERO

## Cached bezier points used for hit-testing and arrowhead rendering.
var _cached_bezier_points: PackedVector2Array = PackedVector2Array()

var _cached_arrowhead_tip: Vector2 = Vector2.ZERO

var _cached_arrowhead_dir: Vector2 = Vector2.ZERO

## The visible stroke Line2D that renders the cubic bezier path of the arrow.
## Styled with white (default) or highlight color when selected.
@onready var vis_line: Line2D = $VisLine

## An invisible, wider Line2D layered on top of vis_line for click/hit detection.
## Has 14px width and transparent color so the user can easily click on thin arrows.
@onready var hit_line: Line2D = $HitLine

## Iterates arrows managed by ArrowManager that are connected to the given shape
## and calls rebuild_path on them.
static func rebuild_arrows_for_shape(shape: Node, all_arrows: Array[Arrow]) -> void:
	for arrow: Arrow in all_arrows:
		if not is_instance_valid(arrow):
			continue
		var a: Arrow = arrow as Arrow
		if a == null:
			continue
		var start_shape: Node = a._resolve_shape(a.start_shape_path)
		var end_shape: Node = a._resolve_shape(a.end_shape_path)
		if start_shape == shape or end_shape == shape:
			a.rebuild_path()

# ----- CanvasElement-aware helpers -------------------------------------------
## Returns the global edge position for a CanvasElement anchor by reading
## the offset from get_anchor_positions().
static func get_canvas_element_anchor_edge(element: CanvasElement, label: String) -> Vector2:
	var anchors: Array[Dictionary] = element.get_anchor_positions()
	for entry: Dictionary in anchors:
		if entry.get("label", "") == label:
			var local_offset: Vector2 = entry.get("offset", Vector2.ZERO)
			return element.to_global(local_offset)
	return element.global_position

static func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	var ut: float = u * t
	return u * u * u * p0 + 3.0 * u * ut * p1 + 3.0 * t * ut * p2 + t * t * t * p3

func _ready() -> void:
	add_to_group("arrows")
	vis_line.default_color = Color(1, 1, 1)
	vis_line.width = 2.0
	vis_line.antialiased = true
	hit_line.width = 14.0
	hit_line.default_color = Color.TRANSPARENT
	hit_line.antialiased = true

func _exit_tree() -> void:
	if is_instance_valid(start_anchor):
		start_anchor.connected_arrows.erase(self)
	if is_instance_valid(end_anchor):
		end_anchor.connected_arrows.erase(self)

func _draw() -> void:
	if not is_preview and _cached_bezier_points.is_empty():
		return
	if is_preview:
		# In preview mode, draw nothing extra; vis_line handles the path.
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

## Rebuilds the bezier path from the connected elements' current anchor positions.
## Uses the CanvasElement.get_anchor_positions() interface to find anchor offsets.
## Must be called after either element moves or resizes.
func rebuild_path() -> void:
	if start_anchor == null or end_anchor == null:
		# One of the connected elements was deleted; queue free.
		queue_free()
		return
	var p0: Vector2 = start_anchor.get_line_global_position()
	var outward_start: Vector2 = start_anchor.get_normal()
	var p3: Vector2 = end_anchor.get_line_global_position()
	var outward_end: Vector2 = end_anchor.get_normal()
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

# ----- Preview Mode ----------------------------------------------------------
## Configures this arrow as a drag preview. The hit line is hidden and
## vis_line gets preview styling. Only the start anchor is set; the endpoint
## will be updated dynamically via update_preview().
func setup_preview(anchor: LineAnchor) -> void:
	is_preview = true
	start_anchor = anchor
	hit_line.hide()
	vis_line.width = 2.0
	vis_line.default_color = Color(0.6, 0.8, 1.0)
	vis_line.antialiased = true
	vis_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	vis_line.end_cap_mode = Line2D.LINE_CAP_ROUND

## Updates the preview bezier path with a dynamic endpoint.
## Called each frame during arrow drag.
func update_preview(end_pos: Vector2, end_normal: Vector2, is_snapped: bool) -> void:
	if start_anchor == null:
		return
	var p0: Vector2 = start_anchor.global_position
	var outward_start: Vector2 = start_anchor.get_normal()
	var p3: Vector2 = end_pos
	var outward_end: Vector2 = end_normal
	var segment_len: float = p0.distance_to(p3)
	if segment_len < 1.0:
		vis_line.points = PackedVector2Array([p0, p3])
		return
	var reach: float = clampf(segment_len * 0.35, 30.0, 100.0)
	var p1: Vector2 = p0 + outward_start * reach
	var p2: Vector2 = p3 + outward_end * reach
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(PREVIEW_SAMPLES)
	for i: int in PREVIEW_SAMPLES:
		var t: float = float(i) / (PREVIEW_SAMPLES - 1)
		points[i] = _cubic_bezier(p0, p1, p2, p3, t)
	vis_line.points = points
	vis_line.default_color = Color(0.6, 0.8, 1.0, 0.8 if not is_snapped else 1.0)

# ----- Original Arrow API ----------------------------------------------------
## Returns the start shape node resolved from the stored NodePath.
func get_start_shape() -> Node:
	return _resolve_shape(start_shape_path)

## Returns the end shape node resolved from the stored NodePath.
func get_end_shape() -> Node:
	return _resolve_shape(end_shape_path)

# ----- private helpers -------------------------------------------------------
## Unified setter called by Main during selection state changes.
## Matches the CanvasElement API so both types can be treated uniformly.
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

func _resolve_shape(path: NodePath) -> CanvasElement:
	if path.is_empty():
		return null
	var shape: CanvasElement = get_node_or_null(path)
	if not is_instance_valid(shape):
		return null
	return shape

func rebuild_if_connected(element: CanvasElement) -> void:
	var start_shape: CanvasElement = get_start_shape()
	var end_shape: CanvasElement = get_end_shape()
	if start_shape == element or end_shape == element:
		rebuild_path()
