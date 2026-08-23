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
var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()
		_queue_local_pointer_redraw()

## Whether this element is the primary (last-clicked) selection.
## When true, uses stronger highlight; when false, uses dimmer highlight.
var is_primary: bool = false:
	set(value):
		is_primary = value
		queue_redraw()
		_queue_local_pointer_redraw()

# ----- Drag State ------------------------------------------------------------
var line_anchors: Array[LineAnchor]

## World position where the current body drag started.
var _drag_start_world: Vector2 = Vector2.ZERO

## Element position when the current body drag started.
var _drag_start_position: Vector2 = Vector2.ZERO

## Cumulative movement from the previous drag event. This is used to send
## incremental deltas to the other members of a multi-selection.
var _last_drag_delta: Vector2 = Vector2.ZERO

## Last pointer position sampled while the local body drag is active.
var _last_pointer_world: Vector2 = Vector2.ZERO

## True while the element's local pointer adapter owns a body drag.
var _body_drag_active: bool = false

## True while a screen-touch drag is providing authoritative pointer positions.
## This prevents the mouse fallback from overwriting touch input in the same frame.
var _screen_pointer_drag_active: bool = false

## LabelShape uses this to keep a double-click from starting a drag.
var _body_click_drag_allowed: bool = true


func is_body_drag_active() -> bool:
	return _body_drag_active


func prevent_body_drag() -> void:
	_body_click_drag_allowed = false


func _process(_delta: float) -> void:
	if not _body_drag_active or _screen_pointer_drag_active:
		return
	var world_pos: Vector2 = get_global_mouse_position()
	if world_pos.is_equal_approx(_last_pointer_world):
		return
	handle_drag_move({"world_pos": world_pos})


func set_screen_pointer_drag_active(active: bool) -> void:
	_screen_pointer_drag_active = active


func _queue_local_pointer_redraw() -> void:
	var adapter: CanvasItem = get_node_or_null("ShapeButton") as CanvasItem
	if adapter != null:
		adapter.queue_redraw()


## Updates selection state and triggers visual update.
## When deselected, is_primary is cleared.
func set_selected(value: bool) -> void:
	is_selected = value
	if not value:
		is_primary = false
	queue_redraw()


# ----- Local pointer adapter interface ----------------------------------------


## Handles a body click and lets Main update selection.
## The local pointer adapter calls handle_drag_begin immediately afterward.
func handle_click(event: Dictionary) -> bool:
	_body_click_drag_allowed = true
	clicked.emit(event.get("original_event", InputEventMouseButton.new()), self)
	return true


## Returns whether the press should begin a body drag. LabelShape sets this to
## false for its local double-click so opening the editor does not move it.
func should_begin_body_drag() -> bool:
	return _body_click_drag_allowed


## Begins a body drag once the element has been selected by Main.
func handle_drag_begin(event: Dictionary) -> bool:
	if _body_drag_active:
		return false
	if not is_selected:
		return false
	_body_drag_active = true
	_drag_start_world = event.get("world_pos", Vector2.ZERO)
	_drag_start_position = position
	_last_drag_delta = Vector2.ZERO
	_last_pointer_world = _drag_start_world
	drag_start.emit()
	return true


## Applies the pointer delta without recentering the element under the cursor.
func handle_drag_move(event: Dictionary) -> void:
	if not _body_drag_active:
		return
	var pointer_world: Vector2 = event.get("world_pos", Vector2.ZERO)
	_last_pointer_world = pointer_world
	var delta: Vector2 = pointer_world - _drag_start_world
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
	_screen_pointer_drag_active = false
	_last_drag_delta = Vector2.ZERO
	_last_pointer_world = Vector2.ZERO
	drag_stop.emit()
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
