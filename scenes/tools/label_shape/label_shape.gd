## Shape that supports resizing, anchors and labels
@tool
class_name LabelShape
extends CanvasElement

## Emitted when the shape is double-clicked (two clicks within 400ms).
## Main connects to this to open the text editor.
signal double_clicked(shape: Node)
signal resized

enum ShapeMode { OVAL_MODEL, CIRCLE_MODE }

## Handle size in pixels.
const HANDLE_SIZE: float = 32.0

## Shape sub-mode: "oval" or "circle". When set to "circle", rx and ry are
## constrained to equal dimensions. Mode conversion snaps dimensions:
@export var shape_mode: ShapeMode = ShapeMode.OVAL_MODEL

@export var rx: float = 160.0:
	set(value):
		rx = value
		queue_redraw()
		_update_text_display()
		if Engine.is_editor_hint():
			return
		if not is_inside_tree():
			return
		if not anchor_changed.is_connected(Callable()):
			# Delay emission to avoid mid-setter issues
			call_deferred("emit_signal", "anchor_changed")
		resized.emit()

@export var ry: float = 100.0:
	set(value):
		ry = value
		queue_redraw()
		_update_text_display()
		if Engine.is_editor_hint():
			return
		if not is_inside_tree():
			return
		if not anchor_changed.is_connected(Callable()):
			call_deferred("emit_signal", "anchor_changed")
		resized.emit()

## Text displayed on the shape, rendered in a centered auto-scaling Label.
@export var text_content: String = "":
	set(value):
		text_content = value
		_update_text_display()

@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value
		queue_redraw()

@onready var _text_label: Label = $TextLabel


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
		var word_width: float = (
			font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		)
		if is_first_word:
			if word_width > max_width:
				# Word is wider than the available space — counts as a line
				count += 1
			else:
				current_line_width = word_width
			is_first_word = false
		else:
			# Space between words
			var space_width: float = (
				font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
			)
			if current_line_width + space_width + word_width > max_width:
				count += 1
				current_line_width = word_width
			else:
				current_line_width += space_width + word_width
	return max(1, count)


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
