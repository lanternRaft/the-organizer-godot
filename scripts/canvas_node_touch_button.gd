## Local pointer adapter for a CanvasNode's body.
## TouchScreenButton owns the hit shape while CanvasNode remains responsible for
## drawing and for the shared CanvasElement drag lifecycle.
@tool
extends TouchScreenButton

var _latest_event: InputEvent
var _drag_active: bool = false
var _active_touch_index: int = -1
var _screen_drag: bool = false

@onready var canvas_node: CanvasElement = get_parent() as CanvasElement


func _ready() -> void:
	shape_centered = true
	shape_visible = false
	pressed.connect(_on_pressed)
	released.connect(_on_released)


func _input(event: InputEvent) -> void:
	# TouchScreenButton's pressed/released signals do not expose their source
	# event, so retain events before those signals are emitted. This also gives
	# us a global release path when the pointer leaves the node.
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_latest_event = event
			if not mouse_event.pressed and _drag_active:
				_finish_drag(event)
				get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion:
		_latest_event = event
		if _drag_active:
			# Mouse motion is authoritative for desktop input and for Godot's
			# mouse-to-touch emulation.
			_forward_drag(event)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed and _active_touch_index < 0:
			_active_touch_index = touch_event.index
			_latest_event = event
		elif touch_event.index == _active_touch_index:
			_latest_event = event
		if (
			_drag_active
			and touch_event.index == _active_touch_index
			and (not touch_event.pressed or touch_event.canceled)
		):
			_finish_drag(event)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		if drag_event.index == _active_touch_index:
			_latest_event = event
			if _drag_active and _screen_drag:
				_forward_drag(event)
				get_viewport().set_input_as_handled()


func _on_pressed() -> void:
	# A second finger must not take over an existing body drag.
	if _drag_active or canvas_node == null:
		return
	var event: InputEvent = _latest_event
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null:
		_active_touch_index = touch_event.index
		_screen_drag = true
	else:
		_active_touch_index = -1
		_screen_drag = false
	var pointer: Dictionary = _pointer_event(event, true)
	if not canvas_node.is_body_drag_active():
		canvas_node.handle_click(pointer)
	if canvas_node.should_begin_body_drag():
		_drag_active = canvas_node.handle_drag_begin(pointer)
		if _drag_active:
			canvas_node.set_screen_pointer_drag_active(_screen_drag)
	else:
		_drag_active = false
	get_viewport().set_input_as_handled()


func _on_released() -> void:
	if _drag_active:
		_finish_drag(_latest_event)


func _forward_drag(event: InputEvent) -> void:
	if _drag_active and canvas_node != null:
		canvas_node.handle_drag_move(_pointer_event(event, true))


func _finish_drag(event: InputEvent) -> void:
	if not _drag_active or canvas_node == null:
		return
	canvas_node.handle_drag_end(_pointer_event(event, false))
	canvas_node.set_screen_pointer_drag_active(false)
	_drag_active = false
	_active_touch_index = -1
	_screen_drag = false


func _pointer_event(event: InputEvent, pressed_state: bool) -> Dictionary:
	var world_pos: Vector2
	if event is InputEventScreenTouch:
		world_pos = _screen_to_world((event as InputEventScreenTouch).position)
	elif event is InputEventScreenDrag:
		world_pos = _screen_to_world((event as InputEventScreenDrag).position)
	else:
		world_pos = canvas_node.get_global_mouse_position()
	return {
		"world_pos": world_pos,
		"local_pos": canvas_node.to_local(world_pos),
		"pressed": pressed_state,
		"dragged": event is InputEventMouseMotion or event is InputEventScreenDrag,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": event if event != null else InputEventMouseButton.new(),
	}


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position
