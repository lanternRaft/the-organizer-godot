class_name CanvasElement
extends Node2D

## Base class for all draggable, anchor-capable canvas elements (LabelShape, CanvasNode).
## Consolidates selection state, drag lifecycle, grid snapping, group membership,
## anchor point interface, and multi-drag signals.
##
## Subclasses override:
##   - get_anchor_positions() — returns anchor definitions
##   - supports_text_editing() — true if element supports text overlay
##   - shows_in_legend() — true if element appears in the legend

# ----- Signals ---------------------------------------------------------------
## Emitted when the element's anchor positions may have changed
## (after drag-end snap, resize, or position change).
## ArrowManager uses this to update connected arrows.
signal anchor_changed

## Emitted when the element body receives a primary pointer click.
signal clicked(input_event: InputEvent, element: Node)

## Emitted during a multi-drag to broadcast the per-frame incremental delta
## to Main so it can shift all other selected elements by the same amount.
## delta: per-frame movement increment in world-space pixels.
signal multi_drag_moved(delta: Vector2)

## Emitted when a body-drag ends, allowing Main to snap all selected elements.
signal multi_drag_ended

signal drag_start

signal drag_stop

# ----- Selection State -------------------------------------------------------
## Whether this element is currently selected. Controls stroke/highlight style.
var is_selected: bool = false

## Whether this element is the primary (last-clicked) selection.
## When true, uses stronger highlight; when false, uses dimmer highlight.
var is_primary: bool = false

# ----- Drag State ------------------------------------------------------------
## Is it being dragged?
var dragging: bool = false

var line_anchors: Array[LineAnchor]

## Offset between the element's origin and the grab point (where the user
## pressed on the shape). Captured on the first frame of each drag and
## reapplied every frame, so the shape is grabbed from wherever it was
## clicked instead of its center snapping to the cursor.
var _drag_offset: Vector2 = Vector2.ZERO

## Whether _drag_offset has been captured for the currently active drag.
var _drag_offset_captured: bool = false

## State used by ClickHandler's body-drag interface.
var _drag_start_world: Vector2 = Vector2.ZERO
var _drag_start_position: Vector2 = Vector2.ZERO
var _last_drag_delta: Vector2 = Vector2.ZERO
var _body_drag_active: bool = false


## World position where the current drag started.
#var _drag_start_world: Vector2 = Vector2.ZERO
## Element position when the current body-drag started.
#var _drag_start_position: Vector2 = Vector2.ZERO
## Cumulative delta from the previous frame, used to compute incremental delta
## for multi-drag broadcasting. Reset on each drag begin.
#var _last_delta: Vector2 = Vector2.ZERO
func _process(_delta: float) -> void:
	if dragging:
		# Capture the grab offset on the first frame of the drag so the shape
		# keeps its click point under the cursor rather than snapping its
		# origin (center) to the mouse.
		if not _drag_offset_captured:
			_drag_offset = global_position - get_global_mouse_position()
			_drag_offset_captured = true
		global_position = get_global_mouse_position() + _drag_offset
		for arrow: Arrow in get_arrows():
			arrow.rebuild_path()


## Updates selection state and triggers visual update.
## When deselected, is_primary is cleared.
func set_selected(value: bool) -> void:
	is_selected = value
	if not value:
		is_primary = false
	queue_redraw()


# ----- ClickHandler interface -----------------------------------------------


## Handles a body click and lets Main update selection.
func handle_click(event: Dictionary) -> bool:
	_body_drag_active = true
	clicked.emit(event.get("original_event", InputEventMouseButton.new()), self)
	return true


## Begins a body drag once the element has been selected by Main.
func handle_drag_begin(event: Dictionary) -> bool:
	if not is_selected:
		return false
	_body_drag_active = true
	_drag_start_world = event.get("world_pos", Vector2.ZERO)
	_drag_start_position = position
	_last_drag_delta = Vector2.ZERO
	return true


## Applies the pointer delta without recentering the element under the cursor.
func handle_drag_move(event: Dictionary) -> void:
	if not _body_drag_active:
		return
	var delta: Vector2 = event.get("world_pos", Vector2.ZERO) - _drag_start_world
	var incremental: Vector2 = delta - _last_drag_delta
	_last_drag_delta = delta
	position = _drag_start_position + delta
	multi_drag_moved.emit(incremental)
	anchor_changed.emit()


## Ends a body drag and applies the documented 20px movement snap.
func handle_drag_end(_event: Dictionary) -> void:
	if not _body_drag_active:
		return
	position = position.snapped(Vector2(20.0, 20.0))
	anchor_changed.emit()
	multi_drag_ended.emit()
	_body_drag_active = false
	_last_drag_delta = Vector2.ZERO
	queue_redraw()


## Returns all arrows connected to this element's LineAnchors.
func get_arrows() -> Array[Arrow]:
	var result: Array[Arrow] = []
	for anchor: LineAnchor in line_anchors:
		result.append_array(anchor.connected_arrows)
	return result


# ----- Anchor System (virtual) -----------------------------------------------
## Returns an array of anchor definitions, each a Dictionary with keys:
##   "label": String — unique identifier for the anchor (e.g., "top", "left")
##   "offset": Vector2 — local offset from the element's origin
## Subclasses must override this.
func get_anchor_positions() -> Array[Dictionary]:
	return []


# ----- Virtual Properties ----------------------------------------------------
## Whether this element supports text editing (double-click opens text overlay).
## Subclasses override to return true (LabelShape) or keep false (CanvasNode).
func supports_text_editing() -> bool:
	return false


## Whether this element should appear in the legend panel.
## Subclasses override to return true (LabelShape) or keep false (CanvasNode).
func shows_in_legend() -> bool:
	return false


func dragging_stopped() -> void:
	dragging = false
	_drag_offset_captured = false
	drag_stop.emit()
