@tool
class_name ElementPointerArea
extends Area2D

## Shared pointer adapter for a CanvasElement's body.
## Owns the element's hit shape through a child CollisionShape2D and converts
## raw pointer input into the shared CanvasElement click/drag lifecycle.
##
## Presses are hit-tested directly against the CollisionShape2D during the
## _input phase, so they are consumed before Canvas._unhandled_input can treat
## them as empty-canvas clicks. Moves and releases are tracked globally until
## the capturing pointer is released, even when it leaves the shape. Mouse and
## touch event families are deduplicated through the capture state, so both
## input emulation directions (mouse-to-touch and touch-to-mouse) are safe.

## Touch index used when the capture came from the mouse instead of a finger.
const MOUSE_POINTER_INDEX: int = -1

var _drag_active: bool = false
var _captured: bool = false
## Touch index that captured the pointer, or MOUSE_POINTER_INDEX for mouse.
var _pointer_index: int = MOUSE_POINTER_INDEX
## True when the capture came from a ScreenTouch press rather than a mouse press.
var _screen_pointer: bool = false

@onready var _element: CanvasElement = get_parent() as CanvasElement
@onready var _collision_shape: CollisionShape2D = _find_collision_shape()


func _ready() -> void:
	# The adapter performs its own hit-testing in _input; keep it invisible to
	# physics picking and to every other Area2D overlap check.
	collision_layer = 0
	collision_mask = 0
	input_pickable = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_screen_touch(touch_event: InputEventScreenTouch) -> void:
	if touch_event.pressed:
		if _captured:
			# A second finger (or an emulated echo) must not take over the drag,
			# but presses landing on this body should still be consumed.
			if _hit_test(touch_event.position):
				get_viewport().set_input_as_handled()
			return
		if _hit_test(touch_event.position):
			_begin_capture(touch_event.index, true, touch_event)
			get_viewport().set_input_as_handled()
		return
	if _captured and _screen_pointer and touch_event.index == _pointer_index:
		# Release or cancellation of the capturing finger.
		_finish_capture(touch_event)
		get_viewport().set_input_as_handled()


func _handle_screen_drag(drag_event: InputEventScreenDrag) -> void:
	if _drag_active and _screen_pointer and drag_event.index == _pointer_index:
		_move_pointer(drag_event)
		get_viewport().set_input_as_handled()


func _handle_mouse_button(mouse_event: InputEventMouseButton) -> void:
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		if _captured:
			# Emulated echo of an already-captured touch press.
			if _screen_pointer and _hit_test(mouse_event.position):
				get_viewport().set_input_as_handled()
			return
		if _hit_test(mouse_event.position):
			_begin_capture(MOUSE_POINTER_INDEX, false, mouse_event)
			get_viewport().set_input_as_handled()
		return
	if _captured and not _screen_pointer:
		_finish_capture(mouse_event)
		get_viewport().set_input_as_handled()


func _handle_mouse_motion(motion_event: InputEventMouseMotion) -> void:
	if _drag_active and not _screen_pointer:
		_move_pointer(motion_event)
		get_viewport().set_input_as_handled()


func _begin_capture(pointer_index: int, from_screen_pointer: bool, event: InputEvent) -> void:
	_captured = true
	_pointer_index = pointer_index
	_screen_pointer = from_screen_pointer
	if _element == null:
		return
	var pointer: Dictionary = _pointer_event(event, true)
	if not _element.is_body_drag_active():
		_element.handle_click(pointer)
	if _element.should_begin_body_drag():
		_drag_active = _element.handle_drag_begin(pointer)
		if _drag_active:
			_element.set_screen_pointer_drag_active(from_screen_pointer)
	else:
		_drag_active = false


func _move_pointer(event: InputEvent) -> void:
	if _drag_active and _element != null:
		_element.handle_drag_move(_pointer_event(event, true))


func _finish_capture(event: InputEvent) -> void:
	if not _captured:
		return
	if _drag_active and _element != null:
		_element.handle_drag_end(_pointer_event(event, false))
		_element.set_screen_pointer_drag_active(false)
	_drag_active = false
	_captured = false
	_pointer_index = MOUSE_POINTER_INDEX
	_screen_pointer = false


func _pointer_event(event: InputEvent, pressed_state: bool) -> Dictionary:
	var world_pos: Vector2 = _screen_to_world(_event_screen_position(event))
	return {
		"world_pos": world_pos,
		"local_pos": _element.to_local(world_pos),
		"pressed": pressed_state,
		"dragged": event is InputEventMouseMotion or event is InputEventScreenDrag,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": event,
	}


func _event_screen_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.ZERO


func _find_collision_shape() -> CollisionShape2D:
	for child: Node in get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


## Hit-tests a viewport-space position against the child CollisionShape2D so
## presses never depend on physics picking order.
func _hit_test(screen_position: Vector2) -> bool:
	if _collision_shape == null:
		return false
	var shape: Shape2D = _collision_shape.shape
	if shape == null:
		return false
	var shape_point: Vector2 = _collision_shape.to_local(_screen_to_world(screen_position))
	if shape is CircleShape2D:
		return shape_point.length() <= (shape as CircleShape2D).radius
	if shape is ConvexPolygonShape2D:
		return Geometry2D.is_point_in_polygon(shape_point, (shape as ConvexPolygonShape2D).points)
	if shape is RectangleShape2D:
		var half_size: Vector2 = (shape as RectangleShape2D).size * 0.5
		return absf(shape_point.x) <= half_size.x and absf(shape_point.y) <= half_size.y
	return false


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position
