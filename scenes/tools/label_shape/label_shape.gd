class_name LabelShape
extends Node2D

## Oval shape rendered via custom drawing (ellipse fill + stroke).
## Supports click-to-select via Area2D child and resize via 4 corner handles.

## Emitted when the oval is clicked (left mouse button press) in Select mode.
signal clicked(input_event: InputEvent, shape: Node)

@export var rx: float = 40.0:
	set(value):
		rx = value
		queue_redraw()
		_update_collision_shape()
		_update_handle_positions()

@export var ry: float = 25.0:
	set(value):
		ry = value
		queue_redraw()
		_update_collision_shape()
		_update_handle_positions()

@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value
		queue_redraw()

## Whether this shape is currently selected. Controls stroke style and handle visibility.
var is_selected: bool = false

## Handle being dragged, or "" if none.
var _dragging_handle: String = ""

@onready var _area_2d: Area2D = $Area2D
@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var _handle_tl: ColorRect = $HandleTL
@onready var _handle_tr: ColorRect = $HandleTR
@onready var _handle_bl: ColorRect = $HandleBL
@onready var _handle_br: ColorRect = $HandleBR

## Handle size in pixels.
const HANDLE_SIZE: float = 8.0


func _ready() -> void:
	modulate.a = 0.9
	_area_2d.set("mouse_filter", 1)  # MOUSE_FILTER_STOP
	_update_collision_shape()
	_update_handle_positions()
	_set_handles_visible(false)
	_area_2d.input_event.connect(_on_area_2d_input_event)


## Forwards left-click events from the Area2D to the clicked signal.
## Marks the event as handled so it doesn't reach _unhandled_input in Main.
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		clicked.emit(event, self)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var stroke_color: Color
	var stroke_width: float

	if is_selected:
		stroke_color = fill_color.lightened(0.4)
		stroke_width = 3.0
	else:
		stroke_color = fill_color.darkened(0.4)
		stroke_width = 2.0

	draw_ellipse(Vector2.ZERO, rx, ry, fill_color)
	draw_ellipse(Vector2.ZERO, rx, ry, stroke_color, false, stroke_width)


## Updates selection state, visuals, and handle visibility.
func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()
	_set_handles_visible(value)


func _set_handles_visible(val: bool) -> void:
	_handle_tl.visible = val
	_handle_tr.visible = val
	_handle_bl.visible = val
	_handle_br.visible = val


func _update_collision_shape() -> void:
	if not is_node_ready():
		return
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.set("extents", Vector2(rx, ry))
	_collision_shape.shape = shape


func _update_handle_positions() -> void:
	if not is_node_ready():
		return
	var half: float = HANDLE_SIZE / 2.0
	_handle_tl.position = Vector2(-rx - half, -ry - half)
	_handle_tr.position = Vector2(rx - half, -ry - half)
	_handle_bl.position = Vector2(-rx - half, ry - half)
	_handle_br.position = Vector2(rx - half, ry - half)


func _input(event: InputEvent) -> void:
	if not is_selected:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var local_pos: Vector2 = to_local(get_global_mouse_position())
				_dragging_handle = _handle_at_pos(local_pos)
				if _dragging_handle != "":
					get_viewport().set_input_as_handled()
			else:
				if _dragging_handle != "":
					_dragging_handle = ""
					get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and _dragging_handle != "":
		var local_pos: Vector2 = to_local(get_global_mouse_position())
		var new_rx: float = rx
		var new_ry: float = ry

		match _dragging_handle:
			"br":
				new_rx = snapped(local_pos.x, 10.0)
				new_ry = snapped(local_pos.y, 10.0)
			"bl":
				new_rx = snapped(-local_pos.x, 10.0)
				new_ry = snapped(local_pos.y, 10.0)
			"tr":
				new_rx = snapped(local_pos.x, 10.0)
				new_ry = snapped(-local_pos.y, 10.0)
			"tl":
				new_rx = snapped(-local_pos.x, 10.0)
				new_ry = snapped(-local_pos.y, 10.0)

		rx = clamp(new_rx, 20.0, 500.0)
		ry = clamp(new_ry, 20.0, 500.0)
		get_viewport().set_input_as_handled()


## Returns the handle name ("tl", "tr", "bl", "br") if local_pos is within a handle rect,
## or an empty string if no handle is hit.
func _handle_at_pos(local_pos: Vector2) -> String:
	var half: float = HANDLE_SIZE / 2.0
	var corners: Dictionary[String, Vector2] = {
		"tl": Vector2(-rx - half, -ry - half),
		"tr": Vector2(rx - half, -ry - half),
		"bl": Vector2(-rx - half, ry - half),
		"br": Vector2(rx - half, ry - half),
	}

	for key: String in corners:
		var pos: Vector2 = corners[key]
		var rect: Rect2 = Rect2(pos, Vector2(HANDLE_SIZE, HANDLE_SIZE))
		if rect.has_point(local_pos):
			return key

	return ""
