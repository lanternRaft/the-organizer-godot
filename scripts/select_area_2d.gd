@tool
extends Area2D

@export var resize: bool = false

var label_shape: LabelShape

## The SelectArea2D's CollisionShape2D, if present. The triangle node uses a
## CollisionPolygon2D instead, so this may be null there.
var _select_shape: CollisionShape2D
var _last_drag_world: Vector2 = Vector2.ZERO

var _drag_active: bool = false

@onready var canvas_element: CanvasElement = $".."


func _ready() -> void:
	# Connect the input_event signal to itself
	input_event.connect(_on_input_event)
	if resize:
		_select_shape = get_node_or_null("CollisionShape2D")
		label_shape = canvas_element
		label_shape.resized.connect(_sync_label_shape)
		_sync_label_shape()


func _input(event: InputEvent) -> void:
	# A local Area2D only receives input_event while the pointer is over its
	# collision shape. Listen here as well so a drag can finish outside the
	# element and continue to use the element's own drag lifecycle.
	if event is InputEventMouseMotion and _drag_active:
		_last_drag_world = canvas_element.get_global_mouse_position()
		canvas_element.call("handle_drag_move", _pointer_event(event, true))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.button_index == MOUSE_BUTTON_LEFT and not button_event.pressed:
			if _drag_active:
				canvas_element.call("handle_drag_end", _pointer_event(event, false))
				_drag_active = false
				get_viewport().set_input_as_handled()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# The SelectArea2D is the element's local pointer entry point. It handles
	# selection and starts the drag without doing a physics query or recentering
	# the element under the cursor.
	if not event is InputEventMouseButton:
		return
	var button_event: InputEventMouseButton = event
	if button_event.button_index != MOUSE_BUTTON_LEFT or not button_event.pressed:
		return

	var pointer_event: Dictionary = _pointer_event(event, true)
	if not canvas_element.call("is_body_drag_active"):
		canvas_element.call("handle_click", pointer_event)
	if canvas_element.call("should_begin_body_drag"):
		_last_drag_world = pointer_event["world_pos"]
		_drag_active = canvas_element.call("handle_drag_begin", pointer_event)
	else:
		_drag_active = false
	get_viewport().set_input_as_handled()


func _pointer_event(event: InputEvent, pressed: bool) -> Dictionary:
	return {
		"world_pos": canvas_element.get_global_mouse_position(),
		"local_pos": canvas_element.to_local(canvas_element.get_global_mouse_position()),
		"pressed": pressed,
		"dragged": event is InputEventMouseMotion,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": event,
	}


## Matches the SelectArea2D footprint to the LabelShape's ellipse by sampling
## its rim (via LabelShape.build_collision_polygon()) into a ConvexPolygonShape2D.
## Circle mode (rx == ry) is handled automatically, and non-LabelShape parents
## (e.g. CanvasNode) are a no-op.
func _sync_label_shape() -> void:
	# Reuse an existing ConvexPolygonShape2D resource if present, else create one.
	var shape: ConvexPolygonShape2D = _select_shape.shape as ConvexPolygonShape2D
	if shape == null:
		shape = ConvexPolygonShape2D.new()
		_select_shape.shape = shape
	shape.points = label_shape.build_collision_polygon()
