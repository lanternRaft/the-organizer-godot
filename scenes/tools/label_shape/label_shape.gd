class_name LabelShape
extends Node2D

## Oval shape rendered via custom drawing (ellipse fill + stroke).
## Supports click-to-select via Area2D child and resize via 4 corner handles.

## Emitted when the oval is clicked in Select mode.
## Emitted from handle_click before drag-begin is evaluated.
signal clicked(input_event: InputEvent, shape: Node)

## Shape sub-mode: "oval" or "circle". When set to "circle", rx and ry are
## constrained to equal dimensions. Mode conversion snaps dimensions:
## oval → circle uses max(rx, ry); circle → oval keeps rx and resets ry=50.
@export var shape_mode: String = "oval":
	set(value):
		shape_mode = value
		if value == "circle":
			var new_r: float = max(rx, ry)
			rx = new_r
			ry = new_r
		elif value == "oval":
			ry = 50.0


@export var rx: float = 80.0:
	set(value):
		rx = value
		queue_redraw()
		_update_collision_shape()
		_update_handle_positions()

@export var ry: float = 50.0:
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

## Current drag mode: "handle", "body", or "" if idle.
var _drag_mode: String = ""

## Handle being dragged, or "" if none (only valid when _drag_mode == "handle").
var _dragging_handle: String = ""

## World position where the current drag started.
var _drag_start_world: Vector2 = Vector2.ZERO

## Shape position when the current body-drag started.
var _drag_start_position: Vector2 = Vector2.ZERO

@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var _handle_tl: ColorRect = $HandleTL
@onready var _handle_tr: ColorRect = $HandleTR
@onready var _handle_bl: ColorRect = $HandleBL
@onready var _handle_br: ColorRect = $HandleBR

## Handle size in pixels.
const HANDLE_SIZE: float = 32.0


func _ready() -> void:
	add_to_group("clickable")
	modulate.a = 0.9
	_update_collision_shape()
	_update_handle_positions()
	_set_handles_visible(false)


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
	var handle_color: Color = Color(0.85, 0.9, 1.0)  # Light blue for visibility
	_handle_tl.position = Vector2(-rx - half, -ry - half)
	_handle_tl.color = handle_color
	_handle_tr.position = Vector2(rx - half, -ry - half)
	_handle_tr.color = handle_color
	_handle_bl.position = Vector2(-rx - half, ry - half)
	_handle_bl.color = handle_color
	_handle_br.position = Vector2(rx - half, ry - half)
	_handle_br.color = handle_color


# ClickHandler interface methods
## Called by ClickHandler when a pointer-down hits this shape's Area2D.
## Detects handle vs. body hit, emits clicked signal, and returns true.
func handle_click(event: Dictionary) -> bool:
	var local_pos: Vector2 = event.get("local_pos", Vector2.ZERO)
	var handle: String = handle_at_pos(local_pos)

	if handle != "":
		_dragging_handle = handle
		_drag_mode = "handle"
	else:
		_dragging_handle = ""
		_drag_mode = "body"

	clicked.emit(event["original_event"], self)
	return true


## Called by ClickHandler after handle_click, same pointer-down cycle.
## Returns true only if the shape is selected and a drag mode is set.
func handle_drag_begin(event: Dictionary) -> bool:
	if not is_selected:
		return false
	if _drag_mode == "":
		return false

	_drag_start_world = event.get("world_pos", Vector2.ZERO)
	_drag_start_position = position
	return true


## Called by ClickHandler on mouse move while drag is active.
func handle_drag_move(event: Dictionary) -> void:
	var local_pos: Vector2 = event.get("local_pos", Vector2.ZERO)
	var world_pos: Vector2 = event.get("world_pos", Vector2.ZERO)

	if _drag_mode == "handle":
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

		# In circle mode, constrain both dimensions to the dominant axis.
		if shape_mode == "circle":
			var dominant: float = max(new_rx, new_ry)
			new_rx = dominant
			new_ry = dominant

		rx = clamp(new_rx, 20.0, 500.0)
		ry = clamp(new_ry, 20.0, 500.0)

	elif _drag_mode == "body":
		var delta: Vector2 = world_pos - _drag_start_world
		position = _drag_start_position + delta


## Called by ClickHandler on pointer up while drag is active.
func handle_drag_end(_event: Dictionary) -> void:
	if _drag_mode == "body":
		position = position.snapped(Vector2(20.0, 20.0))
	_drag_mode = ""
	_dragging_handle = ""
	queue_redraw()


## Returns the handle name ("tl", "tr", "bl", "br") if local_pos is within a handle rect,
## or an empty string if no handle is hit.
func handle_at_pos(local_pos: Vector2) -> String:
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
