class_name ArrowManager
extends Node

## Manages anchor dots, arrow drag, creation, and deletion.
## Child of Main; populates AnchorLayer with visual dot nodes and owns the
## arrow preview line.

const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")

## Hover radius around an anchor dot position for triggering visibility (world-space).
const ANCHOR_HOVER_RADIUS: float = 20.0

## Snap radius for arrow endpoint attachment (world-space).
const SNAP_RADIUS: float = 15.0

## Distance threshold for clicking an arrow path (world-space).
const ARROW_CLICK_DISTANCE: float = 7.0

## Offset of anchor dots from ellipse edge (world-space).
const ANCHOR_OFFSET: float = 5.0

## Dot visual constants.
const DOT_RADIUS_NORMAL: float = 4.0
const DOT_RADIUS_HOVER: float = 7.0
const DOT_COLOR_FILL: Color = Color(1, 1, 1)
const DOT_COLOR_STROKE: Color = Color(0.23, 0.51, 0.965)  # #3b82f6
const DOT_COLOR_HOVER_FILL: Color = Color(0.23, 0.51, 0.965)  # #3b82f6

## Default anchor labels for LabelShape.
const SHAPE_ANCHOR_LABELS: Array[String] = ["top", "bottom", "left", "right"]

## ----- State ---------------------------------------------------------------

## List of all LabelShape instances currently in ElementLayer.
var _shapes: Array[Node] = []

## Anchor dot nodes currently visible in AnchorLayer (up to 4 per shape).
var _dot_nodes: Dictionary = {}  # shape_instance_id -> {label: Node2D}

## Arrow drag state.
var _arrow_drag_active: bool = false
var _drag_start_shape: Node = null
var _drag_start_label: String = ""
var _drag_start_pos: Vector2 = Vector2.ZERO  # edge position, world-space
var _drag_snapped_shape: Node = null
var _drag_snapped_label: String = ""
var _drag_snapped_pos: Vector2 = Vector2.ZERO  # edge position, world-space

## Preview line shown during drag.
var _preview_line: Line2D = null

## All active arrows (children of ElementLayer).
var _arrows: Array[Node] = []

## Signals from ClickHandler (connected in _ready).
var _click_handler: Node = null

@onready var element_layer: Node2D = %ElementLayer
@onready var anchor_layer: Node2D = %AnchorLayer


func _ready() -> void:
	_click_handler = get_parent().get_node("ClickHandler")
	# We'll connect after scene tree is ready — click_handler signals are wired
	# via a custom method that ClickHandler calls when no click target is found.
	# But for arrow creation we intercept at a higher level: Main will route
	# pointer events to us when in Select mode.

	# Scan for existing shapes.
	_refresh_shape_list()

	# Listen for new shapes being added.
	element_layer.child_entered_tree.connect(_on_element_child_added)
	element_layer.child_exiting_tree.connect(_on_element_child_removed)


func _process(_delta: float) -> void:
	var main: Node = get_parent()
	if not main.get("select_mode_active"):
		_hide_all_dots()
		return

	var mouse_pos: Vector2 = element_layer.get_global_mouse_position()
	_update_anchor_dots(mouse_pos)

	if _arrow_drag_active:
		_update_drag_preview(mouse_pos)


# ----- Public API ------------------------------------------------------------

## Returns a list of all active arrows.
func get_arrows() -> Array[Node]:
	return _arrows


## Begins an arrow drag from the given shape's anchor.
func begin_arrow_drag(shape: Node, anchor_label: String) -> void:
	var main: Node = get_parent()
	if not main.get("select_mode_active"):
		return

	_arrow_drag_active = true
	_drag_start_shape = shape
	_drag_start_label = anchor_label
	_drag_start_pos = get_anchor_edge_position(shape, anchor_label)
	_drag_snapped_shape = null
	_drag_snapped_label = ""

	# Create preview line if needed.
	if _preview_line == null:
		_preview_line = Line2D.new()
		_preview_line.width = 2.0
		_preview_line.default_color = Color(0.6, 0.8, 1.0)
		_preview_line.antialiased = true
		_preview_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_preview_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		# Use a dashed appearance by setting a pattern.
		_preview_line.show()
	element_layer.add_child(_preview_line)

	# Show all shapes' anchors during drag.
	_show_all_anchors()


## Ends an arrow drag. Creates arrow if valid, otherwise discards.
func end_arrow_drag() -> void:
	_arrow_drag_active = false

	# Remove preview line.
	if _preview_line != null and _preview_line.get_parent() != null:
		_preview_line.get_parent().remove_child(_preview_line)
		_preview_line.queue_free()
	_preview_line = null

	# If snapped to a valid different shape, create arrow.
	if _drag_snapped_shape != null and _drag_snapped_shape != _drag_start_shape:
		_create_arrow(_drag_start_shape, _drag_start_label, _drag_snapped_shape, _drag_snapped_label)

	_drag_start_shape = null
	_drag_start_label = ""
	_drag_snapped_shape = null
	_drag_snapped_label = ""
	_drag_snapped_pos = Vector2.ZERO


## Returns the nearest arrow hit within the given world-space distance, or null.
func get_arrow_near(pos: Vector2, radius: float = ARROW_CLICK_DISTANCE) -> Variant:
	# Iterate in reverse (topmost first) for proper z-ordering.
	for i: int in range(_arrows.size() - 1, -1, -1):
		var arrow_node: Node = _arrows[i]
		if not is_instance_valid(arrow_node):
			_arrows.remove_at(i)
			continue
		var arrow: Node = arrow_node
		if arrow == null:
			continue
		var points: Variant = arrow.get("_cached_bezier_points")
		if not (points is PackedVector2Array):
			continue
		var pts: PackedVector2Array = points
		for j: int in pts.size() - 1:
			var nearest: Vector2 = _closest_point_on_segment(pos, pts[j], pts[j + 1])
			if pos.distance_to(nearest) <= radius:
				return arrow
	return null


## Deletes the given arrow.
func delete_arrow(arrow: Node) -> void:
	if not is_instance_valid(arrow):
		return
	_arrows.erase(arrow)
	if arrow.get_parent() != null:
		arrow.get_parent().remove_child(arrow)
	arrow.queue_free()


## Called by Main when a shape is being deleted; removes connected arrows first.
func delete_arrows_for_shape(shape: Node) -> void:
	var to_remove: Array[Node] = []
	for arrow_node: Node in _arrows:
		if not is_instance_valid(arrow_node):
			to_remove.append(arrow_node)
			continue
		var start_shape: Variant = arrow_node.call("_resolve_shape", arrow_node.get("start_shape_path"))
		var end_shape: Variant = arrow_node.call("_resolve_shape", arrow_node.get("end_shape_path"))
		if start_shape == shape or end_shape == shape:
			to_remove.append(arrow_node)

	for a: Node in to_remove:
		delete_arrow(a)


## Deletes all arrows.
func delete_all_arrows() -> void:
	while _arrows.size() > 0:
		var arrow: Node = _arrows[0]
		if is_instance_valid(arrow):
			arrow.queue_free()
		_arrows.remove_at(0)


## Rebuilds paths for all arrows connected to the given shape.
func update_arrows_for_shape(shape: Node) -> void:
	for arrow_node: Node in _arrows:
		if not is_instance_valid(arrow_node):
			continue
		var start_shape: Variant = arrow_node.call("_resolve_shape", arrow_node.get("start_shape_path"))
		var end_shape: Variant = arrow_node.call("_resolve_shape", arrow_node.get("end_shape_path"))
		if start_shape == shape or end_shape == shape:
			arrow_node.call("rebuild_path")


# ----- Static utility methods ------------------------------------------------

## Returns the edge position (on the ellipse boundary) for an anchor label.
## Uses duck-typing: if the element has get_anchor_position(label), uses that.
## Falls back to ellipse-based calculation for LabelShape.
static func get_anchor_edge_position(shape: Node, label: String) -> Vector2:
	# CanvasNode and similar elements provide their own anchor positions.
	if shape.has_method(&"get_anchor_position"):
		@warning_ignore("unsafe_cast")
		var pos: Vector2 = shape.call(&"get_anchor_position", label)
		return pos
	# Default LabelShape ellipse-based calculation.
	var rx: float = shape.get("rx")
	var ry: float = shape.get("ry")
	var local_pos: Vector2
	match label:
		"top": local_pos = Vector2(0, -ry)
		"bottom": local_pos = Vector2(0, ry)
		"left": local_pos = Vector2(-rx, 0)
		"right": local_pos = Vector2(rx, 0)
		_: # fallback
			local_pos = Vector2.ZERO
	var shape_2d: Node2D = shape as Node2D
	if shape_2d != null:
		return shape_2d.to_global(local_pos)
	return local_pos


## Returns the list of anchor labels for a given element, using duck-typing.
## If the element has get_anchor_points(), calls it.
## Falls back to SHAPE_ANCHOR_LABELS for LabelShape compatibility.
static func _get_element_anchor_labels(element: Node) -> Array[String]:
	if element.has_method(&"get_anchor_points"):
		var result: Variant = element.call(&"get_anchor_points")
		if result is Array:
			@warning_ignore("unsafe_cast")
			return result as Array[String]
	return SHAPE_ANCHOR_LABELS


## Returns the global anchor dot position for a given element and label.
## Uses duck-typing: if the element has get_anchor_position(label), uses that.
## Falls back to ellipse-based calculation for LabelShape.
static func _get_element_anchor_position(element: Node, label: String) -> Vector2:
	if element.has_method(&"get_anchor_position"):
		@warning_ignore("unsafe_cast")
		var pos: Vector2 = element.call(&"get_anchor_position", label)
		return pos
	# Default LabelShape ellipse-based calculation.
	var rx: float = element.get("rx")
	var ry: float = element.get("ry")
	var local_pos: Vector2
	match label:
		"top": local_pos = Vector2(0, -ry - ANCHOR_OFFSET)
		"bottom": local_pos = Vector2(0, ry + ANCHOR_OFFSET)
		"left": local_pos = Vector2(-rx - ANCHOR_OFFSET, 0)
		"right": local_pos = Vector2(rx + ANCHOR_OFFSET, 0)
		_: local_pos = Vector2.ZERO
	var element_2d: Node2D = element as Node2D
	if element_2d != null:
		return element_2d.to_global(local_pos)
	return local_pos


## Returns the outward normal for an anchor label.
static func get_anchor_outward_normal(label: String) -> Vector2:
	match label:
		"top": return Vector2(0, -1)
		"bottom": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
	return Vector2.ZERO


# ----- Private helpers: shape tracking ---------------------------------------

func _refresh_shape_list() -> void:
	_shapes.clear()
	for child: Node in element_layer.get_children():
		if child is LabelShape or child.has_method("get_anchor_points"):
			_shapes.append(child)


func _on_element_child_added(child: Node) -> void:
	if child is LabelShape or child.has_method("get_anchor_points"):
		_shapes.append(child)
		child.connect("tree_exiting", Callable(self, "_on_shape_tree_exiting").bind(child))


func _on_element_child_removed(child: Node) -> void:
	_shapes.erase(child)
	# Remove dot nodes for this shape.
	_remove_dot_nodes_for_shape(child)
	# Remove connected arrows.
	delete_arrows_for_shape(child)


func _on_shape_tree_exiting(shape: Node) -> void:
	_shapes.erase(shape)
	_remove_dot_nodes_for_shape(shape)


# ----- Private helpers: anchor dots ------------------------------------------

func _update_anchor_dots(mouse_pos: Vector2) -> void:
	var nearest_dist: float = INF
	var nearest_shape: Node = null
	var nearest_label: String = ""

	for shape: Node in _shapes:
		if not is_instance_valid(shape):
			continue

		var labels: Array[String] = _get_element_anchor_labels(shape)
		var shape_shown: bool = false

		for label: String in labels:
			var dot_pos: Vector2 = _get_dot_position(shape, label)
			var dist: float = mouse_pos.distance_to(dot_pos)

			if dist <= ANCHOR_HOVER_RADIUS:
				shape_shown = true

			if dist < nearest_dist:
				nearest_dist = dist
				nearest_shape = shape
				nearest_label = label

		# Show/hide dots for this shape based on hover proximity.
		if shape_shown or _arrow_drag_active:			_show_dots_for_shape(shape)
		else:
			_hide_dots_for_shape(shape)

	# Highlight the nearest dot across all shapes.
	_highlight_dot(nearest_shape, nearest_label, nearest_dist)


func _show_dots_for_shape(shape: Node) -> void:
	var sid: int = shape.get_instance_id()
	if not _dot_nodes.has(sid):
		_dot_nodes[sid] = {}

	var labels: Array[String] = _get_element_anchor_labels(shape)
	for label: String in labels:
		if not label in _dot_nodes[sid]:
			var dot: Node2D = _create_dot(shape, label)
			anchor_layer.add_child(dot)
			_dot_nodes[sid][label] = dot
		else:
			var dot: Variant = _dot_nodes[sid][label]
			@warning_ignore("unsafe_cast")
			var dot_n: Node2D = dot as Node2D
			if dot_n != null:
				dot_n.visible = true
				dot_n.position = _get_dot_position(shape, label)


func _hide_dots_for_shape(shape: Node) -> void:
	var sid: int = shape.get_instance_id()
	if not _dot_nodes.has(sid):
		return
	for label: String in _dot_nodes[sid]:
		var dot: Node2D = _dot_nodes[sid][label]
		if is_instance_valid(dot):
			dot.visible = false


func _show_all_anchors() -> void:
	for shape: Node in _shapes:
		if is_instance_valid(shape):
			_show_dots_for_shape(shape)


func _hide_all_dots() -> void:
	for sid: Variant in _dot_nodes:
		for label: String in _dot_nodes[sid]:
			var dot: Node2D = _dot_nodes[sid][label]
			if is_instance_valid(dot):
				dot.visible = false


func _remove_dot_nodes_for_shape(shape: Node) -> void:
	var sid: int = shape.get_instance_id()
	if not _dot_nodes.has(sid):
		return
	for label: String in _dot_nodes[sid]:
		var dot: Node2D = _dot_nodes[sid][label]
		if is_instance_valid(dot):
			dot.queue_free()
	_dot_nodes.erase(sid)


func _create_dot(shape: Node, label: String) -> Node2D:
	var dot: Node2D = Node2D.new()
	dot.set_script(preload("res://scenes/arrow_manager/anchor_dot.gd"))
	dot.position = _get_dot_position(shape, label)
	dot.set_meta("parent_shape", shape)
	dot.set_meta("anchor_label", label)
	dot.set_meta("dot_radius", DOT_RADIUS_NORMAL)
	dot.set_meta("dot_fill", DOT_COLOR_FILL)
	dot.set_meta("dot_stroke", DOT_COLOR_STROKE)
	dot.set_meta("is_highlighted", false)
	dot.queue_redraw()
	return dot


func _highlight_dot(shape: Node, label: String, dist: float) -> void:
	var should_snap: bool = false
	if shape != null and label != "" and dist <= DOT_RADIUS_HOVER:
		should_snap = true

	# Update all dots to ensure only the nearest (if within hover radius) is highlighted.
	for sid: Variant in _dot_nodes:
		for lbl: String in _dot_nodes[sid]:
			var dot: Variant = _dot_nodes[sid][lbl]
			@warning_ignore("unsafe_cast")
			var dot_n: Node2D = dot as Node2D
			if dot_n == null:
				continue
			
			var is_highlighted: bool = false
			if should_snap and shape != null and sid == shape.get_instance_id() and lbl == label:
				is_highlighted = true

			var prev: Variant = dot_n.get_meta("is_highlighted", false)
			if is_highlighted != prev:
				if is_highlighted:
					dot_n.set_meta("dot_radius", DOT_RADIUS_HOVER)
					dot_n.set_meta("dot_fill", DOT_COLOR_HOVER_FILL)
				else:
					dot_n.set_meta("dot_radius", DOT_RADIUS_NORMAL)
					dot_n.set_meta("dot_fill", DOT_COLOR_FILL)
				dot_n.set_meta("is_highlighted", is_highlighted)
				dot_n.queue_redraw()

	# If drag is active, update snap preview to this dot (or clear if not snapping).
	if _arrow_drag_active:
		if should_snap and shape != null:
			_drag_snapped_shape = shape
			_drag_snapped_label = label
			_drag_snapped_pos = get_anchor_edge_position(shape, label)
		else:
			_drag_snapped_shape = null
			_drag_snapped_label = ""
			_drag_snapped_pos = Vector2.ZERO



func _get_dot_position(shape: Node, label: String) -> Vector2:
	return _get_element_anchor_position(shape, label)


# ----- Private helpers: drag preview -----------------------------------------

func _update_drag_preview(mouse_pos: Vector2) -> void:
	if _preview_line == null:
		return

	var p0: Vector2 = _drag_start_pos
	var outward_start: Vector2 = get_anchor_outward_normal(_drag_start_label)

	# Determine end position: snapped or free.
	var p3: Vector2
	var outward_end: Vector2
	var _snapped: bool = false

	if _drag_snapped_shape != null and _drag_snapped_shape != _drag_start_shape:
		p3 = _drag_snapped_pos
		outward_end = get_anchor_outward_normal(_drag_snapped_label)
		_snapped = true
	else:
		p3 = mouse_pos
		outward_end = Vector2.ZERO

	var segment_len: float = p0.distance_to(p3)
	if segment_len < 1.0:
		_preview_line.points = PackedVector2Array([p0, p3])
		return

	var reach: float = clampf(segment_len * 0.35, 30.0, 100.0)
	var p1: Vector2 = p0 + outward_start * reach
	var p2: Vector2 = p3 + outward_end * reach

	var points: PackedVector2Array = PackedVector2Array()
	var samples: int = 20
	points.resize(samples)
	for i: int in samples:
		var t: float = float(i) / (samples - 1)
		points[i] = _cubic_bezier(p0, p1, p2, p3, t)

	_preview_line.points = points
	_preview_line.default_color = Color(0.6, 0.8, 1.0, 0.8 if not _snapped else 1.0)


# ----- Private helpers: arrow creation ---------------------------------------

func _create_arrow(start_shape: Node, start_label: String, end_shape: Node, end_label: String) -> void:
	var raw_arrow: Variant = ARROW_SCENE.instantiate()
	@warning_ignore("unsafe_cast")
	var arrow: Node = raw_arrow as Node
	if arrow == null:
		return

	# Add to ElementLayer (will be below shapes in z-order).
	element_layer.add_child(arrow)
	element_layer.move_child(arrow, 0)  # Keep arrows at bottom of element layer

	# Set paths relative to the arrow itself so it can resolve them later
	arrow.set("start_shape_path", arrow.get_path_to(start_shape))
	arrow.set("end_shape_path", arrow.get_path_to(end_shape))
	arrow.set("start_anchor_label", start_label)
	arrow.set("end_anchor_label", end_label)

	arrow.call("rebuild_path")

	_arrows.append(arrow)

	# Connect signal for multi-drag coordination so Main can move all selected
	# elements when this arrow is dragged.
	if arrow.has_signal(&"multi_drag_moved"):
		var main: Node = get_parent()
		if main.has_method(&"_on_multi_drag_moved"):
			arrow.connect("multi_drag_moved", Callable(main, "_on_multi_drag_moved").bind(arrow))


func _on_element_layer_click(mouse_pos: Vector2) -> bool:
	## Called from Main when no shape was hit — allows arrow click detection.
	var arrow: Variant = get_arrow_near(mouse_pos)
	if arrow != null:
		@warning_ignore("unsafe_cast")
		var arrow_n: Node = arrow as Node
		if arrow_n != null:
			arrow_n.call("emit", "selected", arrow_n)
		return true
	return false


# ----- Private helpers: geometry ---------------------------------------------

static func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.0001:
		return a
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return a + ab * t


static func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	var ut: float = u * t
	return u * u * u * p0 + 3.0 * u * ut * p1 + 3.0 * t * ut * p2 + t * t * t * p3


# ----- Called by Main when clicking empty canvas ----------------------------

## Handles mousedown on the anchor dot layer. Returns true if consumed.
func handle_dot_mousedown(mouse_pos: Vector2) -> bool:
	var main: Node = get_parent()
	if not main.get("select_mode_active"):
		return false

	# Check if mouse is over any highlighted anchor dot.
	for shape: Node in _shapes:
		if not is_instance_valid(shape):
			continue
		var labels: Array[String] = _get_element_anchor_labels(shape)
		for label: String in labels:
			var dot_pos: Vector2 = _get_dot_position(shape, label)
			if mouse_pos.distance_to(dot_pos) <= DOT_RADIUS_HOVER:
				begin_arrow_drag(shape, label)
				return true

	return false


## Handles mouseup on canvas during arrow drag.
func handle_dot_mouseup() -> void:
	if _arrow_drag_active:
		end_arrow_drag()