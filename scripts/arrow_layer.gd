class_name ArrowLayer
extends Node2D

## Manages anchor dots, arrow drag, creation, and deletion.
## Child of Main; populates AnchorLayer with visual dot nodes and owns the
## arrow preview line.
##
## All anchor-capable elements (LabelShape, CanvasNode) expose their anchor
## positions via the CanvasElement.get_anchor_positions() virtual method,
## which returns an Array[Dictionary] each with "label" and "offset" keys.
## This manager reads that interface generically — no per-type logic.

const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")

## Distance threshold for clicking an arrow path (world-space).
const ARROW_CLICK_DISTANCE: float = 7.0

## ----- State ---------------------------------------------------------------

## List of all CanvasElement instances currently in ElementLayer.
var _elements: Array[CanvasElement] = []

## Arrow drag state.
var _arrow_drag_active: bool = false
var _drag_start_anchor: LineAnchor
var _drag_snapped_anchor: LineAnchor

## Preview line shown during drag.
var _preview_line: Line2D = null

## Signals from ClickHandler (connected in _ready).
var _click_handler: Node = null

@onready var element_layer: Node2D = %ElementLayer
@onready var anchor_layer: Node2D = %AnchorLayer
@onready var toolbar: Toolbar = %Toolbar


func _ready() -> void:
	EventBus.line_drag_start.connect(_line_drag_start)
	EventBus.line_drag_stop.connect(_line_drag_stop)
	EventBus.anchor_highlight.connect(_anchor_highlight)
	_click_handler = get_parent().get_node("ClickHandler")

	# Scan for existing elements.
	_refresh_element_list()

	# Listen for new elements being added.
	element_layer.child_entered_tree.connect(_on_element_child_added)
	element_layer.child_exiting_tree.connect(_on_element_child_removed)

func _anchor_highlight(line_anchor: LineAnchor) -> void:
	_drag_snapped_anchor = line_anchor

## Ends an arrow drag. Creates arrow if valid, otherwise discards.
func _line_drag_stop(_line_anchor: LineAnchor) -> void:
	if not _drag_start_anchor:
		return
	_arrow_drag_active = false

	# Remove preview line.
	if _preview_line != null and _preview_line.get_parent() != null:
		_preview_line.get_parent().remove_child(_preview_line)
		_preview_line.queue_free()
	_preview_line = null

	# If snapped to a valid different element, create arrow.
	if _drag_snapped_anchor != null and _drag_snapped_anchor.get_element() != _drag_start_anchor.get_element():
		_create_arrow(_drag_start_anchor, _drag_snapped_anchor)

func _line_drag_start(line_anchor: LineAnchor) -> void:
	_arrow_drag_active = true
	_drag_start_anchor = line_anchor
	_drag_snapped_anchor = null

	if _preview_line == null:
		_preview_line = Line2D.new()
		_preview_line.width = 2.0
		_preview_line.default_color = Color(0.6, 0.8, 1.0)
		_preview_line.antialiased = true
		_preview_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_preview_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		_preview_line.show()
	element_layer.add_child(_preview_line)

func _process(_delta: float) -> void:
	#if not toolbar.select_mode_active:
		##_hide_all_dots()
		#return

	var mouse_pos: Vector2 = element_layer.get_global_mouse_position()
	#_update_anchor_dots(mouse_pos)

	if _arrow_drag_active:
		_update_drag_preview(mouse_pos)


# ----- Public API ------------------------------------------------------------


## Returns a list of all active arrows.
func get_arrows() -> Array[Arrow]:
	var _arrows: Array[Arrow] = get_children() as Array[Arrow]
	return _arrows



## Returns the nearest arrow hit within the given world-space distance, or null.
func get_arrow_near(pos: Vector2, radius: float = ARROW_CLICK_DISTANCE) -> Arrow:
	# Iterate in reverse (topmost first) for proper z-ordering.
	var arrows: Array[Arrow] = get_arrows()
	for i: int in range(arrows.size() - 1, -1, -1):
		var arrow_node: Arrow = arrows[i]
		if not is_instance_valid(arrow_node):
			arrows.remove_at(i)
			continue
		var arrow: Arrow = arrow_node
		if arrow == null:
			continue
		var points: PackedVector2Array = arrow._cached_bezier_points
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
	if arrow.get_parent() != null:
		arrow.get_parent().remove_child(arrow)
	arrow.queue_free()


## Called by Main when an element is being deleted; removes connected arrows first.
func delete_arrows_for_element(element: CanvasElement) -> void:
	var to_remove: Array[Arrow] = []
	for arrow_node: Arrow in get_arrows():
		if not is_instance_valid(arrow_node):
			to_remove.append(arrow_node)
			continue
		var start_shape: CanvasElement = arrow_node.get_start_shape()
		var end_shape: CanvasElement = arrow_node.get_end_shape()
		if start_shape == element or end_shape == element:
			to_remove.append(arrow_node)

	for a: Arrow in to_remove:
		delete_arrow(a)


## Deletes all arrows.
func delete_all_arrows() -> void:
	for arrow: Arrow in get_arrows():
		arrow.queue_free()


## Rebuilds paths for all arrows connected to the given CanvasElement.
func update_arrows_for_element(element: CanvasElement) -> void:
	for arrow_node: Arrow in get_arrows():
		if not is_instance_valid(arrow_node):
			continue

		arrow_node.rebuild_if_connected(element)


# ----- Anchor Position Helpers (uses CanvasElement interface) ----------------


## Returns the global edge position for a given element and anchor label.
## Reads offsets from the element's get_anchor_positions() virtual method.
static func _get_anchor_edge_global_position(element: CanvasElement, label: String) -> Vector2:
	var anchors: Array[Dictionary] = element.get_anchor_positions()
	for entry: Dictionary in anchors:
		if entry.get("label", "") == label:
			var local_offset: Vector2 = entry.get("offset", Vector2.ZERO)
			return element.to_global(local_offset)
	# Fallback: return element's origin.
	return element.global_position


## Returns the global dot position (with outward offset) for a given element and anchor label.
## Uses same get_anchor_positions() data, adding an outward push for visual clearance.
static func _get_anchor_dot_global_position(element: CanvasElement, label: String) -> Vector2:
	var anchors: Array[Dictionary] = element.get_anchor_positions()
	for entry: Dictionary in anchors:
		if entry.get("label", "") == label:
			var local_offset: Vector2 = entry.get("offset", Vector2.ZERO)
			# Push the dot slightly outward from the edge for visual clarity.
			var outward_dir: Vector2 = local_offset.normalized()
			if outward_dir.length_squared() < 0.001:
				outward_dir = Vector2.DOWN
			return element.to_global(local_offset + outward_dir * 5.0)
	# Fallback.
	return element.global_position


## Returns the list of anchor labels for a given element, read from get_anchor_positions().
static func _get_anchor_labels_from_element(element: CanvasElement) -> Array[String]:
	var labels: Array[String] = []
	var anchors: Array[Dictionary] = element.get_anchor_positions()
	for entry: Dictionary in anchors:
		var label_v: Variant = entry.get("label", "")
		if label_v is String:
			var label: String = label_v
			if not label.is_empty():
				labels.append(label)
	return labels


## Returns the outward normal for an anchor label by reading the offset from get_anchor_positions().
## Falls back to axis-aligned normals for cardinal directions as a convenience.
static func _get_anchor_outward_normal(element: CanvasElement, label: String) -> Vector2:
	var anchors: Array[Dictionary] = element.get_anchor_positions()
	for entry: Dictionary in anchors:
		if entry.get("label", "") == label:
			var offset: Vector2 = entry.get("offset", Vector2.ZERO)
			if offset.length_squared() > 0.001:
				return offset.normalized()
	# Fallback for cardinal directions (works for most elements).
	match label:
		"top":
			return Vector2(0, -1)
		"bottom":
			return Vector2(0, 1)
		"left":
			return Vector2(-1, 0)
		"right":
			return Vector2(1, 0)
	return Vector2.ZERO


# ----- Private helpers: element tracking -------------------------------------


func _refresh_element_list() -> void:
	_elements.clear()
	for child: Node in element_layer.get_children():
		if child is CanvasElement:
			_elements.append(child)


func _on_element_child_added(child: Node) -> void:
	if child is CanvasElement:
		_elements.append(child)
		child.connect("tree_exiting", Callable(self, "_on_element_tree_exiting").bind(child))


func _on_element_child_removed(child: Node) -> void:
	_elements.erase(child)
	# Remove dot nodes for this element.
	#_remove_dot_nodes_for_element(child as CanvasElement)
	# Remove connected arrows.
	var canvas_elem: CanvasElement = child as CanvasElement
	if canvas_elem != null:
		delete_arrows_for_element(canvas_elem)


func _on_element_tree_exiting(element: CanvasElement) -> void:
	_elements.erase(element)
	#_remove_dot_nodes_for_element(element)


func _get_dot_position(element: CanvasElement, label: String) -> Vector2:
	return _get_anchor_dot_global_position(element, label)


# ----- Private helpers: drag preview -----------------------------------------


func _update_drag_preview(mouse_pos: Vector2) -> void:
	if _preview_line == null || _arrow_drag_active == false || _drag_start_anchor == null:
		return

	var p0: Vector2 = _drag_start_anchor.global_position
	var outward_start: Vector2 = _drag_start_anchor.get_normal()

	# Determine end position: snapped or free.
	var p3: Vector2
	var outward_end: Vector2
	var drag_snapped: bool = false

	if _drag_snapped_anchor != null and _drag_snapped_anchor != _drag_start_anchor:
		p3 = _drag_snapped_anchor.global_position
		outward_end = _drag_snapped_anchor.get_normal()
		drag_snapped = true
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
		points[i] = Arrow._cubic_bezier(p0, p1, p2, p3, t)

	_preview_line.points = points
	_preview_line.default_color = Color(0.6, 0.8, 1.0, 0.8 if not drag_snapped else 1.0)


# ----- Private helpers: arrow creation ---------------------------------------


func _create_arrow(start_anchor: LineAnchor, end_anchor: LineAnchor) -> void:
	var arrow: Arrow = ARROW_SCENE.instantiate()

	add_child(arrow)

	arrow.start_anchor = start_anchor
	arrow.end_anchor = end_anchor
	arrow.rebuild_path()


func _on_element_layer_click(mouse_pos: Vector2) -> bool:
	## Called from Main when no element was hit — allows arrow click detection.
	var arrow: Arrow = get_arrow_near(mouse_pos)
	if arrow != null:
		var arrow_n: Arrow = arrow
		if arrow_n != null:
			arrow_n.selected.emit()
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
