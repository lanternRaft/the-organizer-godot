## Local pointer adapter and renderer for a LabelShape's ellipse body.
## TouchScreenButton owns both the sampled hit shape and the ellipse drawing so
## the visual and interactive footprints cannot drift apart.
@tool
extends TouchScreenButton

var _latest_event: InputEvent
var _drag_active: bool = false
var _active_touch_index: int = -1
var _screen_drag: bool = false
var _polygon_shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()

@onready var label_shape: LabelShape = get_parent() 


func _ready() -> void:
	label_shape.resized.connect(_sync_shape)
	pressed.connect(_on_pressed)
	released.connect(_on_released)
	
	_sync_shape()


func _draw() -> void:
	var stroke_color: Color
	var stroke_width: float
	if label_shape.is_selected:
		if label_shape.is_primary:
			stroke_color = label_shape.fill_color.lightened(0.4)
			stroke_width = 3.0
		else:
			stroke_color = label_shape.fill_color.lightened(0.25)
			stroke_width = 2.5
	else:
		stroke_color = label_shape.fill_color.darkened(0.4)
		stroke_width = 2.0
	draw_ellipse(Vector2.ZERO, label_shape.rx, label_shape.ry, label_shape.fill_color)
	draw_ellipse(Vector2.ZERO, label_shape.rx, label_shape.ry, stroke_color, false, stroke_width)


func _sync_shape() -> void:
	_polygon_shape.points = label_shape.build_collision_polygon()
	queue_redraw()


func _input(event: InputEvent) -> void:
	# TouchScreenButton's pressed/released signals do not expose their source
	# event, so retain events before those signals are emitted. This also gives
	# us a global release path when the pointer leaves the ellipse.
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
			# Mouse motion remains authoritative for desktop input and for
			# Godot's mouse-to-touch emulation. Real touch devices additionally
			# provide screen-drag events, which are forwarded below.
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
	if _drag_active:
		return
	var event: InputEvent = _latest_event
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null:
		_active_touch_index = touch_event.index
		_screen_drag = true
	else:
		_active_touch_index = -1
		_screen_drag = false
	if event == null:
		event = null
	var pointer: Dictionary = _pointer_event(event, true)
	var canvas_element: CanvasElement = label_shape
	if not canvas_element.is_body_drag_active():
		canvas_element.handle_click(pointer)
	if canvas_element.should_begin_body_drag():
		_drag_active = canvas_element.handle_drag_begin(pointer)
		if _drag_active:
			canvas_element.call("set_screen_pointer_drag_active", _screen_drag)
	else:
		_drag_active = false
	get_viewport().set_input_as_handled()


func _on_released() -> void:
	if _drag_active:
		_finish_drag(_latest_event)


func _forward_drag(event: InputEvent) -> void:
	if not _drag_active:
		return
	label_shape.handle_drag_move(_pointer_event(event, true))


func _finish_drag(event: InputEvent) -> void:
	if not _drag_active:
		return
	label_shape.handle_drag_end(_pointer_event(event, false))
	label_shape.call("set_screen_pointer_drag_active", false)
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
		world_pos = label_shape.get_global_mouse_position()
	return {
		"world_pos": world_pos,
		"local_pos": label_shape.to_local(world_pos),
		"pressed": pressed_state,
		"dragged": event is InputEventMouseMotion or event is InputEventScreenDrag,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": event if event != null else InputEventMouseButton.new(),
	}


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position
