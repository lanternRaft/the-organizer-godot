class_name SelectionMenu
extends PanelContainer

## Floating contextual menu that appears below a single selected element.
## Shows Delete and Color actions. Auto-hides based on selection state.
##
## Positioned in screen-space (child of UI CanvasLayer in Main scene).

signal delete_requested()
signal color_selected(color: Color)

## Padding below the element's bounding box (screen-space pixels).
const BELOW_PADDING: float = 12.0

## Reference to the element this menu is currently positioned for.
var _target_element: Node2D = null

## Cached reference to the main camera for coordinate conversion.
var _main_camera: Camera2D = null

## Cached viewport for clamping.
var _viewport: Viewport = null

@onready var delete_button: Button = %DeleteButton
@onready var color_button: Button = %ColorButton
@onready var _color_palette: Control = %ColorPalette


func _ready() -> void:
	_viewport = get_viewport()
	_main_camera = _viewport.get_camera_2d()

	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks behind the menu.

	delete_button.pressed.connect(_on_delete_pressed)
	color_button.pressed.connect(_on_color_button_pressed)
	_color_palette.connect("color_selected", _on_palette_color_selected)


## Positions the menu below the given element and makes it visible.
## Connects to the element's anchor_changed signal for repositioning on move/resize.
## @param element: The selected Node2D element (LabelShape, Arrow, etc.).
func show_for_element(element: Node2D) -> void:
	if not is_instance_valid(element) or not element.is_inside_tree():
		dismiss()
		return

	# Disconnect previous anchor connection if any.
	if _target_element != null and _target_element.has_signal(&"anchor_changed"):
		if _target_element.is_connected(&"anchor_changed", refresh_position):
			_target_element.disconnect(&"anchor_changed", refresh_position)

	_target_element = element
	visible = true
	_reposition()

	# Follow element movement/resize.
	if element.has_signal(&"anchor_changed"):
		if not element.is_connected(&"anchor_changed", refresh_position):
			element.connect(&"anchor_changed", refresh_position)


## Hides the menu. Named dismiss to avoid overriding CanvasItem.hide().
func dismiss() -> void:
	if _target_element != null and _target_element.has_signal(&"anchor_changed"):
		if _target_element.is_connected(&"anchor_changed", refresh_position):
			_target_element.disconnect(&"anchor_changed", refresh_position)
	visible = false
	_color_palette.visible = false
	_target_element = null


## Returns the currently targeted element (or null if hidden).
func get_target_element() -> Node2D:
	return _target_element


## Recalculates screen position based on the target element's world bounds.
## Called after element moves, camera pans, or zoom changes.
func _reposition() -> void:
	if _target_element == null or not is_instance_valid(_target_element):
		return

	var camera: Camera2D = _main_camera
	if camera == null:
		camera = _viewport.get_camera_2d()
		_main_camera = camera
	if camera == null:
		return

	# Get element's world position and visual extents.
	var world_pos: Vector2 = _target_element.global_position
	var half_width: float = 80.0  # Fallback default
	var half_height: float = 50.0

	if _target_element.has_method("get_rx"):
		half_width = _target_element.get("rx")
	if _target_element.has_method("get_ry"):
		half_height = _target_element.get("ry")

	# For arrows, estimate from cached bezier points.
	if _target_element.is_in_group("arrows"):
		var pts_v: Variant = _target_element.get("_cached_bezier_points")
		if pts_v != null and typeof(pts_v) == TYPE_PACKED_VECTOR2_ARRAY:
			var pts: PackedVector2Array = pts_v
			if not pts.is_empty():
				var min_x: float = INF
				var max_x: float = -INF
				var min_y: float = INF
				var max_y: float = -INF
				for p: Vector2 in pts:
					min_x = min(min_x, p.x)
					max_x = max(max_x, p.x)
					min_y = min(min_y, p.y)
					max_y = max(max_y, p.y)
				world_pos = Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
				half_width = (max_x - min_x) / 2.0
				half_height = (max_y - min_y) / 2.0

	# Convert world center to screen space.
	var canvas_transform: Transform2D = camera.get_canvas_transform()
	var screen_center: Vector2 = canvas_transform * world_pos

	# Calculate the element's screen-space bounding box.
	var zoom_scale: Vector2 = camera.zoom
	var _screen_half_w: float = half_width * zoom_scale.x
	var screen_half_h: float = half_height * zoom_scale.y

	# Determine size to use for centering and clamping.
	var vp_size: Vector2 = _viewport.get_visible_rect().size
	var menu_size: Vector2 = size
	if menu_size == Vector2.ZERO:
		# Size may not be ready yet; use custom_minimum_size as fallback.
		menu_size = custom_minimum_size
	if menu_size == Vector2.ZERO:
		# Reasonable fallback if both are zero.
		menu_size = Vector2(80, 40)

	# Position menu centered horizontally below the element.
	var menu_pos: Vector2 = Vector2(
		screen_center.x - menu_size.x / 2.0,
		screen_center.y + screen_half_h + BELOW_PADDING
	)

	# Clamp to viewport edges so the menu stays on-screen.
	menu_pos.x = clampf(menu_pos.x, 0.0, vp_size.x - menu_size.x)
	menu_pos.y = clampf(menu_pos.y, 0.0, vp_size.y - menu_size.y)

	position = menu_pos


## Called when element moves or camera pans/zooms.
func refresh_position() -> void:
	_reposition()


## --- Signal handlers ---

func _on_delete_pressed() -> void:
	delete_requested.emit()


func _on_color_button_pressed() -> void:
	if _color_palette.visible:
		_color_palette.visible = false
	else:
		# Position the palette to the right of the color button.
		var btn_global: Vector2 = color_button.global_position
		_color_palette.global_position = Vector2(
			btn_global.x + color_button.size.x + 4.0,
			btn_global.y
		)
		# Clamp to viewport.
		var vp_size: Vector2 = _viewport.get_visible_rect().size
		var pal_size: Vector2 = _color_palette.size
		if _color_palette.global_position.x + pal_size.x > vp_size.x:
			_color_palette.global_position.x = vp_size.x - pal_size.x
		if _color_palette.global_position.y + pal_size.y > vp_size.y:
			_color_palette.global_position.y = vp_size.y - pal_size.y
		_color_palette.call("open")


func _on_palette_color_selected(color: Color) -> void:
	color_selected.emit(color)