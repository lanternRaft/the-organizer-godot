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

## Maximum interval between local body presses for a double-click.
const DOUBLE_CLICK_TIME_MS: int = 400

## Shape sub-mode: "oval" or "circle". When set to "circle", rx and ry are
## constrained to equal dimensions. Mode conversion snaps dimensions:
@export var shape_mode: ShapeMode = ShapeMode.OVAL_MODEL

@export var rx: float = 160.0:
	set(value):
		rx = value
		#_update_text_display()
		_sync_anchors()
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
		#_update_text_display()
		_sync_anchors()
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
		#_update_text_display()

@export var fill_color: Color = Color(0.231, 0.51, 0.965):
	set(value):
		fill_color = value

var _last_body_click_time: int = 0


func _ready() -> void:
	_sync_anchors()
	var handles: CanvasItem = get_node_or_null("Handles") as CanvasItem
	if handles != null:
		handles.visible = false


#@onready var _text_label: Label = $TextLabel
## Detects double-clicks at the shape's own local pointer adapter entry point. Main only
## reacts to the resulting signal; it never performs global double-click tests.
func handle_click(event: Dictionary) -> bool:
	var now: int = Time.get_ticks_msec()
	var is_double_click: bool = (
		_last_body_click_time > 0 and now - _last_body_click_time < DOUBLE_CLICK_TIME_MS
	)
	_last_body_click_time = now
	if is_double_click:
		call("prevent_body_drag")
		double_clicked.emit(self)
		return true
	return super.handle_click(event)


# ----- Collision Geometry ----------------------------------------------------
## Samples the ellipse rim into a packed polygon, optionally scaled. This is the
## single source of truth for ellipse hit-test shapes: the touch button calls it
## at scale 1.0 and AnchorShowArea2D at 1.2 (Godot has no natively-rounded ellipse
## 2D shape, so a sampled polygon is the closest hit-test approximation to
## draw_ellipse()). Circle mode (rx == ry) is handled automatically.
func build_collision_polygon(scale_factor: float = 1.0) -> PackedVector2Array:
	# Sample the ellipse perimeter with ~half a point per pixel of radius,
	# clamped to a sane range so tiny shapes aren't over-sampled.
	var steps: int = clampi(int(maxf(rx, ry) * 0.5), 16, 96)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in steps:
		var angle: float = TAU * float(i) / float(steps)
		points.append(Vector2(cos(angle) * rx * scale_factor, sin(angle) * ry * scale_factor))
	return points


# ----- Text Display ---------------------------------------------------------
## Updates the Label text and rescales the font to fit the shape bounds.
#func _update_text_display() -> void:
#if not is_node_ready() or _text_label == null:
#return
## Position the label to fill the shape's inner area with padding.
#var pad: float = 10.0
#var label_size: Vector2 = Vector2(2.0 * rx - 2.0 * pad, 2.0 * ry - 2.0 * pad)
#_text_label.position = Vector2(-rx + pad, -ry + pad)
#_text_label.size = label_size
#_text_label.text = text_content
#_rescale_text_font()
## Auto-scales font size so the full text (word-wrapped) fits vertically
## within the shape's inner bounds. Starts at 20px and decreases until
## the text fits or minimum 8px is reached.
#func _rescale_text_font() -> void:
#if not is_node_ready() or _text_label == null:
#return
#var pad: float = 10.0
#var available_width: float = max(1.0, 2.0 * rx - 2.0 * pad)
#var available_height: float = max(1.0, 2.0 * ry - 2.0 * pad)
#if text_content.is_empty():
#return
#var font: Font = _text_label.get_theme_default_font()
#var font_size: int = 20
#while font_size >= 8:
#var line_height: float = font.get_height(font_size)
#var line_count: int = _estimate_line_count(text_content, available_width, font, font_size)
#var total_height: float = float(line_count) * line_height * 1.2
#if total_height <= available_height:
#break
#font_size -= 1
#_text_label.add_theme_font_size_override("font_size", font_size)
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


# ----- Resize / Selection ----------------------------------------------------
## Repositions the LineAnchor children to the current rim (rx/ry) so connected
## arrows stay glued to the shape while it resizes. get_anchor_positions() is
## the source of truth for where each cardinal anchor sits.
func _sync_anchors() -> void:
	if not is_node_ready():
		return
	var anchors_node: Node = get_node_or_null("Anchors")
	if anchors_node == null:
		return
	for defn: Dictionary in get_anchor_positions():
		var label: String = str(defn.get("label", ""))
		var offset: Vector2 = defn.get("offset", Vector2.ZERO)
		for child: Node in anchors_node.get_children():
			if child is LineAnchor and _anchor_matches_label(child as LineAnchor, label):
				(child as LineAnchor).position = offset
				break


## Matches a LineAnchor child to a cardinal label from get_anchor_positions().
func _anchor_matches_label(anchor: LineAnchor, label: String) -> bool:
	match label:
		"top":
			return anchor.anchor_position == LineAnchor.AnchorPosition.TOP
		"bottom":
			return anchor.anchor_position == LineAnchor.AnchorPosition.BOTTOM
		"left":
			return anchor.anchor_position == LineAnchor.AnchorPosition.LEFT
		"right":
			return anchor.anchor_position == LineAnchor.AnchorPosition.RIGHT
		_:
			return false


## Shows/hides the resize handles with the selection state.
func set_selected(value: bool) -> void:
	super.set_selected(value)
	var handles: CanvasItem = get_node_or_null("Handles") as CanvasItem
	if handles != null:
		handles.visible = value


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
