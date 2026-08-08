## Manages anchor dots, arrow drag, creation, and deletion.
## Child of Main; populates AnchorLayer with visual dot nodes and owns the
## arrow preview line.
##
## All anchor-capable elements (LabelShape, CanvasNode) expose their anchor
## positions via the CanvasElement.get_anchor_positions() virtual method,
## which returns an Array[Dictionary] each with "label" and "offset" keys.
## This manager reads that interface generically — no per-type logic.
class_name ArrowLayer
extends Node2D

const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")

## Distance threshold for clicking an arrow path (world-space).
const ARROW_CLICK_DISTANCE: float = 7.0

## Arrow drag state.
var _arrow_drag_active: bool = false
var _drag_start_anchor: LineAnchor
var _drag_snapped_anchor: LineAnchor

## Preview arrow shown during drag.
var _preview_arrow: Arrow = null

@onready var element_layer: Node2D = %ElementLayer
@onready var toolbar: Toolbar = %Toolbar


func _ready() -> void:
	EventBus.line_drag_start.connect(_line_drag_start)
	EventBus.line_drag_stop.connect(_line_drag_stop)
	EventBus.anchor_highlight.connect(_anchor_highlight)


func _process(_delta: float) -> void:
	if _arrow_drag_active:
		var mouse_pos: Vector2 = element_layer.get_global_mouse_position()
		_update_drag_preview(mouse_pos)


func _anchor_highlight(line_anchor: LineAnchor) -> void:
	_drag_snapped_anchor = line_anchor


## Ends an arrow drag. Creates arrow if valid, otherwise discards.
func _line_drag_stop() -> void:
	if not _drag_start_anchor:
		return
	_arrow_drag_active = false

	# Remove preview arrow.
	if _preview_arrow != null and _preview_arrow.get_parent() != null:
		_preview_arrow.get_parent().remove_child(_preview_arrow)
		_preview_arrow.queue_free()
	_preview_arrow = null

	# If snapped to a valid different element, create arrow.
	if (
		_drag_snapped_anchor != null
		and _drag_snapped_anchor.canvas_element != _drag_start_anchor.canvas_element
	):
		_create_arrow(_drag_start_anchor, _drag_snapped_anchor)


func _line_drag_start(line_anchor: LineAnchor) -> void:
	_arrow_drag_active = true
	_drag_start_anchor = line_anchor
	_drag_snapped_anchor = null

	# Create a preview arrow (as a special type of arrow).
	if _preview_arrow == null:
		_preview_arrow = ARROW_SCENE.instantiate()
		element_layer.add_child(_preview_arrow)
		_preview_arrow.setup_preview(line_anchor)


# ----- Public API ------------------------------------------------------------


## Returns a list of all active arrows.
func get_arrows() -> Array[Arrow]:
	var arrows: Array[Arrow] = []
	arrows.assign(get_children())
	return arrows


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


func _update_drag_preview(mouse_pos: Vector2) -> void:
	if _preview_arrow == null || _arrow_drag_active == false || _drag_start_anchor == null:
		return

	# Determine end position: snapped or free.
	var end_pos: Vector2
	var end_normal: Vector2
	var drag_snapped: bool = false

	if _drag_snapped_anchor != null and _drag_snapped_anchor != _drag_start_anchor:
		end_pos = _drag_snapped_anchor.global_position
		end_normal = _drag_snapped_anchor.get_normal()
		drag_snapped = true
	else:
		end_pos = mouse_pos
		end_normal = Vector2.ZERO

	_preview_arrow.update_preview(end_pos, end_normal, drag_snapped)


func _create_arrow(start_anchor: LineAnchor, end_anchor: LineAnchor) -> void:
	var arrow: Arrow = ARROW_SCENE.instantiate()

	add_child(arrow)

	arrow.start_anchor = start_anchor
	arrow.end_anchor = end_anchor
	start_anchor.connected_arrows.append(arrow)
	end_anchor.connected_arrows.append(arrow)
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
