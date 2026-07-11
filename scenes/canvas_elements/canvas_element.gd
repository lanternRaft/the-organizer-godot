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
##   - handle_click() — to customize click behavior
##   - handle_double_click() — to open text editor or other action

# ----- Signals ---------------------------------------------------------------

## Emitted when the element is clicked (pointer-down on body).
## Main connects to this to handle selection logic.
signal clicked(input_event: InputEvent, element: Node)

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


func _ready() -> void:
	add_to_group("clickable")
	add_to_group("clickable_element")

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


# ----- Clickable Interface (duck-typing) -------------------------------------


## Called by ClickHandler when a pointer-down hits this element's Area2D.
## Default implementation: sets drag mode to "body" and emits clicked signal.
## Subclasses (e.g., LabelShape) override to detect handle vs. body hits.
#func handle_click(event: Dictionary) -> bool:
	#dragging = true
	#clicked.emit(event.get("original_event", InputEventMouseButton.new()), self)
	#return true


## Called by ClickHandler when a double-click is detected on this element.
## Default no-op returning true. Subclasses (e.g., LabelShape) override
## to open the text editor.
#func handle_double_click(_event: Dictionary) -> bool:
	#return true


## Called by ClickHandler after handle_click, or when an already-selected
## element is clicked again (multi-drag on an already-selected element).
## Returns true if the element is selected and ready to drag.
### Subclasses may override to detect handle vs. body drag modes.
#func handle_drag_begin(event: Dictionary) -> bool:
	#if not is_selected:
		#return false
	#_drag_start_world = event.get("world_pos", Vector2.ZERO)
	#_drag_start_position = position
	#_last_delta = Vector2.ZERO
	#dragging = true
	#return true


## Called by ClickHandler on mouse move while drag is active.
## Computes incremental delta, updates position, and emits signals.
#func handle_drag_move(event: Dictionary) -> void:
	#if not dragging:
		#return
	#var world_pos: Vector2 = event.get("world_pos", Vector2.ZERO)
	#var delta: Vector2 = world_pos - _drag_start_world
	#var incremental: Vector2 = delta - _last_delta
	#_last_delta = delta
	#position = _drag_start_position + delta
	#multi_drag_moved.emit(incremental)
	#anchor_changed.emit()


## Called by ClickHandler on pointer up while drag is active.
## Snaps position to 20px grid (for body drags) and emits completion signals.
func handle_drag_end(_event: Dictionary) -> void:
	if dragging:
		position = position.snapped(Vector2(20.0, 20.0))
		# Re-notify anchor_changed after snap so arrows match the snapped position.
		anchor_changed.emit()
		# Notify Main to snap other selected elements too.
		multi_drag_ended.emit()
	dragging = false
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
