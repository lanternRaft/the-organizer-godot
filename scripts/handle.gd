@tool
class_name ResizeHandle
extends Control

## A single corner resize handle for shapes. Thin input proxy: it captures
## pointer events through the GUI system (a MOUSE_FILTER_STOP Control wins over
## the shape's body-drag Area2D underneath it) and forwards them to the owning
## Handles manager, which owns all resize geometry.
##
## Corner is a plain int for cross-script friendliness (see the constants
## below) — the .tscn instances set it per handle.

const TOP_LEFT: int = 0
const TOP_RIGHT: int = 1
const BOTTOM_LEFT: int = 2
const BOTTOM_RIGHT: int = 3

## Which corner of the shape's bounding box this handle controls.
@export var corner: int = TOP_LEFT

## The Handles manager (this node's parent).
var _manager: Node2D


func _ready() -> void:
	_manager = get_parent() as Node2D
	var s: float = LabelShape.HANDLE_SIZE
	size = Vector2(s, s)
	position = -size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = _cursor_for_corner()
	# GUI handles own pointer input; keep the skeletal physics collider out of
	# click and point queries so it can never fight the shape's SelectArea2D.
	var area: Area2D = get_node_or_null("Area2D") as Area2D
	if area != null:
		area.input_pickable = false
		area.collision_layer = 0
		area.collision_mask = 0


func _cursor_for_corner() -> Control.CursorShape:
	match corner:
		TOP_LEFT, BOTTOM_RIGHT:
			return Control.CURSOR_BDIAGSIZE
		_:
			return Control.CURSOR_FDIAGSIZE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and _manager != null:
			if mb.pressed:
				_manager.call("handle_resize_start", corner)
			else:
				_manager.call("handle_resize_end")
			accept_event()
	elif event is InputEventMouseMotion and _manager != null and _manager.call("is_resizing"):
		_manager.call("handle_resize_move")
		accept_event()
