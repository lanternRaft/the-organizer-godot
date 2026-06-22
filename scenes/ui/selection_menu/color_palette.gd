class_name SelectionColorPalette
extends Control

## Popup palette of 8 color swatches. Emits color_selected when a swatch is clicked.
## Positioned relative to its parent by the SelectionMenu.

signal color_selected(color: Color)

## 8 colors matching the design spec.
const COLORS: Array[Color] = [
	Color("#3b82f6"),  # Blue   (default fill)
	Color("#ef4444"),  # Red
	Color("#22c55e"),  # Green
	Color("#f59e0b"),  # Amber
	Color("#a855f7"),  # Purple
	Color("#ec4899"),  # Pink
	Color("#ffffff"),  # White
	Color("#1e293b"),  # Dark
]

## Size of each swatch in pixels.
const SWATCH_SIZE: float = 32.0

## Padding between swatches in pixels.
const SWATCH_PADDING: float = 4.0

## Number of columns in the grid.
const COLUMNS: int = 4


func _ready() -> void:
	_build_swatches()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # Prevent clicks from passing through


## Builds the grid of color swatch buttons.
func _build_swatches() -> void:
	for i: int in COLORS.size():
		var color_rect: ColorRect = ColorRect.new()
		color_rect.color = COLORS[i]
		color_rect.size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
		color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

		var col: int = i % COLUMNS
		var row: int = int(float(i) / float(COLUMNS))
		color_rect.position = Vector2(
			col * (SWATCH_SIZE + SWATCH_PADDING) + SWATCH_PADDING,
			row * (SWATCH_SIZE + SWATCH_PADDING) + SWATCH_PADDING
		)

		color_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Make it clickable.
		color_rect.gui_input.connect(_on_swatch_gui_input.bind(color_rect, COLORS[i]))

		add_child(color_rect)

	# Set the palette's own size to fit the grid.
	var total_w: float = COLUMNS * (SWATCH_SIZE + SWATCH_PADDING) + SWATCH_PADDING
	var total_h: float = ceil(float(COLORS.size()) / float(COLUMNS)) * (SWATCH_SIZE + SWATCH_PADDING) + SWATCH_PADDING
	custom_minimum_size = Vector2(total_w, total_h)
	size = custom_minimum_size


## Opens the palette.
func open() -> void:
	visible = true


## Closes the palette.
func close() -> void:
	visible = false


## Handles click on a swatch: emits color_selected and closes.
func _on_swatch_gui_input(event: InputEvent, _swatch: ColorRect, color: Color) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			color_selected.emit(color)
			close()
			get_viewport().set_input_as_handled()