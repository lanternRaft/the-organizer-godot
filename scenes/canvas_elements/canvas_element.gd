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

## World position where the current drag started.
#var _drag_start_world: Vector2 = Vector2.ZERO

## Element position when the current body-drag started.
#var _drag_start_position: Vector2 = Vector2.ZERO

## Cumulative delta from the previous frame, used to compute incremental delta
## for multi-drag broadcasting. Reset on each drag begin.
#var _last_delta: Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position()
		for arrow: Arrow in get_arrows():
			arrow.rebuild_path()


## Updates selection state and triggers visual update.
## When deselected, is_primary is cleared.
func set_selected(value: bool) -> void:
	is_selected = value
	if not value:
		is_primary = false
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
	drag_stop.emit()
