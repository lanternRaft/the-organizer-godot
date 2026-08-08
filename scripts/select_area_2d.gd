@tool
extends Area2D


@export var resize: bool = false
## The SelectArea2D's CollisionShape2D, if present. The triangle node uses a
## CollisionPolygon2D instead, so this may be null there.
var _select_shape: CollisionShape2D
var label_shape: LabelShape

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
	# If the user releases the mouse anywhere outside the Area2D, stop dragging
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.button_index == MOUSE_BUTTON_LEFT and not button_event.pressed:
			canvas_element.dragging_stopped()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Check if the player left-clicks inside the CollisionShape
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				canvas_element.dragging = true
				canvas_element.drag_start.emit()
			else:
				canvas_element.dragging_stopped()


## Matches the SelectArea2D footprint to the LabelShape's ellipse by sampling
## its rim into a ConvexPolygonShape2D (Godot has no natively-rounded ellipse
## 2D shape, so a sampled polygon is the closest hit-test approximation to
## draw_ellipse()). Circle mode (rx == ry) is handled automatically, and
## non-LabelShape parents (e.g. CanvasNode) are a no-op.
func _sync_label_shape() -> void:
	# Sample the ellipse perimeter with ~half a point per pixel of radius,
	# clamped to a sane range so tiny shapes aren't over-sampled.
	var steps: int = clampi(int(maxf(label_shape.rx, label_shape.ry) * 0.5), 16, 96)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in steps:
		var angle: float = TAU * float(i) / float(steps)
		points.append(Vector2(cos(angle) * label_shape.rx, sin(angle) * label_shape.ry))
	# Reuse an existing ConvexPolygonShape2D resource if present, else create one.
	var shape: ConvexPolygonShape2D = _select_shape.shape as ConvexPolygonShape2D
	if shape == null:
		shape = ConvexPolygonShape2D.new()
		_select_shape.shape = shape
	shape.points = points
