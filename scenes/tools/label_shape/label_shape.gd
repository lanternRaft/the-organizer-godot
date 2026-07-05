class_name LabelShape
extends CanvasElement

## Oval shape rendered via custom drawing (ellipse fill + stroke).
## Supports click-to-select via Area2D child and resize via 4 corner handles.
##
## Inherits selection state, drag lifecycle, grid snapping, group membership,
## anchor point interface, and multi-drag signals from CanvasElement.

## Emitted when the shape is double-clicked (two clicks within 400ms).
## Main connects to this to open the text editor.
signal double_clicked(shape: Node)

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
		_update_text_display()
		if Engine.is_editor_hint():
			return
		if not is_inside_tree():
			return
		if not anchor_changed.is_connected(Callable()):
			# Delay emission to avoid mid-setter issues
			call_deferred("emit_signal", "anchor_changed")

@export var ry: float = 50.0:
	set(value):
		ry = value
		queue_redraw()
		_update_collision_shape()
		_update_handle_positions()
		_update_text_display()
		if Engine.is_editor_hint():
			return
		if not is_inside_tree():
			return
		if not anchor_changed.is_connected(Callable()):
			call_deferred("emit_signal", "anchor_changed")

## Text displayed on the shape, rendered in a centered auto-scaling Label.
@export var text_content: String = "":
	set(value):
		text_content = value
		_update_text_display()

@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value
		queue_redraw()

## Handle being dragged, or "" if none (only valid when _drag_mode == "handle").
var _dragging_handle: String = ""

@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var _handle_tl: ColorRect = $HandleTL
@onready var _handle_tr: ColorRect = $HandleTR
@onready var _handle_bl: ColorRect = $HandleBL
@onready var _handle_br: ColorRect = $HandleBR
@onready var _text_label: Label = $TextLabel

## Handle size in pixels.
const HANDLE_SIZE: float = 32.0


func _ready() -> void:
	# CanvasElement._ready() adds to "clickable" and "clickable_element" groups.
	super()
	modulate.a = 0.9
	_update_collision_shape()
	_update_handle_positions()
	_set_handles_visible(false)
	_update_text_display()


func _draw() -> void:
	var stroke_color: Color
	var stroke_width: float

	if is_selected:
		if is_primary:
			stroke_color = fill_color.lightened(0.4)
			stroke_width = 3.0
		else:
			stroke_color = fill_color.lightened(0.25)
			stroke_width = 2.5
	else:
		stroke_color = fill_color.darkened(0.4)
		stroke_width = 2.0

	draw_ellipse(Vector2.ZERO, rx, ry, fill_color)
	draw_ellipse(Vector2.ZERO, rx, ry, stroke_color, false, stroke_width)


func _set_handles_visible(val: bool) -> void:
	_handle_tl.visible = val
	_handle_tr.visible = val
	_handle_bl.visible = val
	_handle_br.visible = val


# ----- Clickable Interface (overrides) ---------------------------------------

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


## Called by ClickHandler when a double-click is detected on this shape.
## Opens the text editor overlay.
func handle_double_click(_event: Dictionary) -> bool:
	double_clicked.emit(self)
	return true


# ----- Drag Lifecycle (overrides for handle/resize) --------------------------

## Called by ClickHandler after handle_click, or when an already-selected
## element is clicked again (multi-drag on an already-selected element).
## Returns true only if the shape is selected and a drag mode is set.
## Overrides CanvasElement.handle_drag_begin to preserve handle detection
## set by handle_click, and to detect handle vs body when handle_click
## was skipped (multi-drag on already-selected element).
func handle_drag_begin(event: Dictionary) -> bool:
	if not is_selected:
		return false
	if _drag_mode == "":
		# handle_click was skipped — detect drag mode from the event.
		var local_pos: Vector2 = event.get("local_pos", Vector2.ZERO)
		var handle: String = handle_at_pos(local_pos)
		if handle != "":
			_dragging_handle = handle
			_drag_mode = "handle"
		else:
			_dragging_handle = ""
			_drag_mode = "body"

	_drag_start_world = event.get("world_pos", Vector2.ZERO)
	_drag_start_position = position
	_last_delta = Vector2.ZERO
	return true


## Called by ClickHandler on mouse move while drag is active.
## Handles both body-drag (movement) and handle-drag (resize).
func handle_drag_move(event: Dictionary) -> void:
	var local_pos: Vector2 = event.get("local_pos", Vector2.ZERO)
	var world_pos: Vector2 = event.get("world_pos", Vector2.ZERO)
	var did_change: bool = false

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
		did_change = true

	elif _drag_mode == "body":
		var delta: Vector2 = world_pos - _drag_start_world
		var incremental: Vector2 = delta - _last_delta
		_last_delta = delta
		position = _drag_start_position + delta
		did_change = true
		# Broadcast incremental delta so Main can apply it additively
		# without accumulating cumulative offsets on siblings.
		multi_drag_moved.emit(incremental)
	if did_change:
		anchor_changed.emit()


## Called by ClickHandler on pointer up while drag is active.
## Snaps position to 20px grid (body drags) and emits completion signals.
func handle_drag_end(_event: Dictionary) -> void:
	if _drag_mode == "body":
		position = position.snapped(Vector2(20.0, 20.0))
		# Re-notify anchor_changed after snap so arrows match the snapped position.
		anchor_changed.emit()
		# Notify Main to snap other selected shapes too.
		multi_drag_ended.emit()
	_drag_mode = ""
	_dragging_handle = ""
	queue_redraw()
	# Notify downstream systems (arrows) that anchor positions may have changed.
	emit_signal("anchor_changed")


# ----- Text Display ---------------------------------------------------------

## Updates the Label text and rescales the font to fit the shape bounds.
func _update_text_display() -> void:
	if not is_node_ready() or _text_label == null:
		return

	# Position the label to fill the shape's inner area with padding.
	var pad: float = 10.0
	var label_size: Vector2 = Vector2(2.0 * rx - 2.0 * pad, 2.0 * ry - 2.0 * pad)
	_text_label.position = Vector2(-rx + pad, -ry + pad)
	_text_label.size = label_size

	_text_label.text = text_content
	_rescale_text_font()


## Auto-scales font size so the full text (word-wrapped) fits vertically
## within the shape's inner bounds. Starts at 20px and decreases until
## the text fits or minimum 8px is reached.
func _rescale_text_font() -> void:
	if not is_node_ready() or _text_label == null:
		return

	var pad: float = 10.0
	var available_width: float = max(1.0, 2.0 * rx - 2.0 * pad)
	var available_height: float = max(1.0, 2.0 * ry - 2.0 * pad)

	if text_content.is_empty():
		return

	var font: Font = _text_label.get_theme_default_font()
	var font_size: int = 20

	while font_size >= 8:
		var line_height: float = font.get_height(font_size)
		var line_count: int = _estimate_line_count(text_content, available_width, font, font_size)
		var total_height: float = float(line_count) * line_height * 1.2

		if total_height <= available_height:
			break
		font_size -= 1

	_text_label.add_theme_font_size_override("font_size", font_size)


## Estimates how many lines the text will wrap into given a width constraint.
## Uses a simple greedy word-wrap algorithm to measure line count.
func _estimate_line_count(text: String, max_width: float, font: Font, font_size: int) -> int:
	if text.is_empty():
		return 1

	var words: PackedStringArray = text.split(" ", false)
	var count: int = 1
	var current_line_width: float = 0.0
	var is_first_word: bool = true

	for word: String in words:
		var word_width: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x

		if is_first_word:
			if word_width > max_width:
				# Word is wider than the available space — counts as a line
				count += 1
			else:
				current_line_width = word_width
			is_first_word = false
		else:
			# Space between words
			var space_width: float = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
			if current_line_width + space_width + word_width > max_width:
				count += 1
				current_line_width = word_width
			else:
				current_line_width += space_width + word_width

	return max(1, count)


# ----- Resize / Position Updates --------------------------------------------

func _update_collision_shape() -> void:
	if not is_node_ready():
		return
	var radius: float = max(rx, ry)
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	_collision_shape.shape = shape


## Returns the radius used for overlap detection: max(rx, ry).
func overlap_radius() -> float:
	return max(rx, ry)


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


# ----- Anchor System (overrides) ---------------------------------------------

## Returns 4 cardinal anchor offsets based on current rx/ry dimensions.
func get_anchor_positions() -> Array[Dictionary]:
	return [
		{"label": "top", "offset": Vector2(0, -ry)},
		{"label": "bottom", "offset": Vector2(0, ry)},
		{"label": "left", "offset": Vector2(-rx, 0)},
		{"label": "right", "offset": Vector2(rx, 0)},
	]


# ----- Virtual Properties (overrides) ----------------------------------------

func supports_text_editing() -> bool:
	return true


func shows_in_legend() -> bool:
	return true