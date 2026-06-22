extends Node

## Root controller of the app. Owns the canvas, camera, UI, and input dispatch.

## Preload LabelShape scene for instantiation.
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")

## Whether shape-placement mode is currently active.
var shape_tool_active: bool = false

## Current shape sub-mode: "oval" or "circle".
var shape_sub_mode: String = "oval"

## Whether select mode is currently active.
var select_mode_active: bool = false

## Reference to the last placed shape (useful for future undo / selection).
var last_placed: Node2D = null

## Most recent zoom level (cached from camera_controller signal).
var current_zoom: float = 1.0

## Whether the grid is currently visible.
var grid_enabled: bool = true

## Currently selected ovals.
var selected_set: Array[LabelShape] = []

## Last-clicked (primary) selection.
var primary_selection: LabelShape = null

@onready var element_layer: Node2D = %ElementLayer
@onready var info_bar: Label = %InfoBar
@onready var canvas: Node2D = %Canvas
@onready var select_button: Button = $UI/Toolbar/HBox/SelectButton
@onready var click_handler: Node = $ClickHandler
@onready var confirm_dialog: AcceptDialog = $UI/ConfirmDialog
@onready var grid_background: ColorRect = %GridBackground
@onready var camera_controller: Node = $CameraController
@onready var zoom_controls: Control = $UI/ZoomControls
@onready var _viewport: Viewport = get_viewport()


func _ready() -> void:
	## Connect ClickHandler's empty-canvas signal for mode-specific actions.
	click_handler.connect("empty_canvas_clicked", _on_empty_canvas_clicked)
	## Start in Select mode by default.
	activate_select_mode()

	## Connect grid toggle signal.
	grid_background.connect("grid_toggled", _on_grid_toggled)

	## Load persisted grid state — it loads inside grid_background._ready().
	grid_enabled = grid_background.get("grid_enabled")

	## Set initial theme (dark) on the grid.
	grid_background.call("set_theme_dark", true)

	## Connect zoom controls to camera controller (string-based to bypass type inference).
	zoom_controls.connect("zoom_in_requested", _on_zoom_in_requested)
	zoom_controls.connect("zoom_out_requested", _on_zoom_out_requested)
	zoom_controls.connect("zoom_reset_requested", _on_zoom_reset_requested)

	## Track zoom changes for the info bar.
	camera_controller.connect("zoom_changed", _on_zoom_changed)


func _unhandled_input(event: InputEvent) -> void:
	## Handle Escape to deactivate Oval mode or clear selection.
	## Keyboard-only — all pointer input is handled by ClickHandler.
	if event.is_action_pressed("ui_cancel"):
		if shape_tool_active:
			deactivate_shape_mode()
			get_viewport().set_input_as_handled()
			return
		if select_mode_active and not selected_set.is_empty():
			clear_selection()
			get_viewport().set_input_as_handled()
			return

	## G key toggles the grid on/off.
	if event.is_action_pressed(&"grid_toggle"):
		toggle_grid()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if (
			key_event.keycode == KEY_G
			and not key_event.ctrl_pressed
			and not key_event.shift_pressed
			and not key_event.alt_pressed
			and key_event.pressed
			and not key_event.echo
		):
			toggle_grid()
			get_viewport().set_input_as_handled()


## Toggles the grid background on/off.
func _on_grid_toggled(enabled: bool) -> void:
	grid_enabled = enabled
	update_info_bar()


## Removes all children from ElementLayer and clears selection.
func clear_all_elements() -> void:
	for child: Node in element_layer.get_children():
		child.queue_free()
	clear_selection()


## Opens the confirmation dialog when the hamburger Clear item is selected.
func _on_hamburger_clear_requested() -> void:
	confirm_dialog.popup_centered()


## Called when the Clear button in the confirmation dialog is pressed.
func _on_confirm_dialog_confirmed() -> void:
	clear_all_elements()


## Creates a new shape at the given world position and parents it to ElementLayer.
## The shape's sub-mode (oval or circle) is determined by the current shape_sub_mode.
## After placement, auto-switches to Select mode and selects the new shape.
func place_shape(world_pos: Vector2) -> void:
	var shape: LabelShape = LABEL_SHAPE_SCENE.instantiate() as LabelShape
	shape.position = world_pos
	shape.shape_mode = shape_sub_mode
	element_layer.add_child(shape)
	last_placed = shape

	# Connect the click signal for selection.
	shape.clicked.connect(_on_shape_clicked)
	# Auto-switch to Select mode and select the new shape.
	deactivate_shape_mode()
	activate_select_mode()
	select_shape(shape, false)
	set_primary_selection(shape)


## Activates shape-placement mode with the given sub-mode. Deactivates Select mode if active.
func activate_shape_mode(sub_mode: String) -> void:
	if select_mode_active:
		deactivate_select_mode()

	shape_tool_active = true
	shape_sub_mode = sub_mode
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	select_button.button_pressed = false
	update_info_bar()


## Deactivates shape-placement mode and returns to neutral state.
func deactivate_shape_mode() -> void:
	shape_tool_active = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	update_info_bar()


## Activates Select mode. Deactivates Shape mode if active.
func activate_select_mode() -> void:
	if shape_tool_active:
		deactivate_shape_mode()

	select_mode_active = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	select_button.button_pressed = true
	update_info_bar()


## Deactivates Select mode and clears selection.
func deactivate_select_mode() -> void:
	select_mode_active = false
	clear_selection()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	select_button.button_pressed = false
	update_info_bar()


## Toggles Shape mode on/off with the given sub-mode. Connected to Toolbar's signal.
func _on_shape_sub_mode_changed(sub_mode: String) -> void:
	activate_shape_mode(sub_mode)


## Toggles Select mode on/off. Connected to Toolbar's signal.
func _on_select_mode_toggled(active: bool) -> void:
	if active:
		activate_select_mode()
	else:
		deactivate_select_mode()


## Called by ClickHandler when a pointer-down lands on empty canvas.
## Routes to the appropriate mode action (placement, selection clear).
func _on_empty_canvas_clicked(world_pos: Vector2) -> void:
	if shape_tool_active:
		place_shape(world_pos)
	elif select_mode_active and not Input.is_key_pressed(KEY_SHIFT):
		clear_selection()


## Handles a click on a shape. Connected to LabelShape.clicked signal.
## Shift-click toggles additive; single click re-selects.
func _on_shape_clicked(_event: InputEvent, shape: LabelShape) -> void:
	if not select_mode_active:
		# In Oval mode, ignore clicks on existing shapes.
		return

	# Shift-click logic.
	var shift: bool = Input.is_key_pressed(KEY_SHIFT)

	if shift:
		if shape in selected_set:
			_deselect_shape(shape)
		else:
			select_shape(shape, true)
			set_primary_selection(shape)
	else:
		if shape in selected_set:
			# Already selected — make it primary (deselect others, keeps this)
			clear_selection()
			select_shape(shape, false)
			set_primary_selection(shape)
		else:
			# New selection
			clear_selection()
			select_shape(shape, false)
			set_primary_selection(shape)
## Adds the shape to the selection set. If additive is false, clears first.
func select_shape(shape: LabelShape, additive: bool = false) -> void:
	if not additive:
		clear_selection()
	if not shape in selected_set:
		selected_set.append(shape)
	shape.set_selected(true)
	update_info_bar()


## Removes the shape from the selection set.
func _deselect_shape(shape: LabelShape) -> void:
	shape.set_selected(false)
	selected_set.erase(shape)
	if primary_selection == shape:
		if selected_set.is_empty():
			primary_selection = null
		else:
			primary_selection = selected_set[-1]
	update_info_bar()


## Sets the primary (last-clicked) selection.
func set_primary_selection(shape: LabelShape) -> void:
	primary_selection = shape


## Clears all selection.
func clear_selection() -> void:
	for shape: LabelShape in selected_set:
		shape.set_selected(false)
	selected_set.clear()
	primary_selection = null
	update_info_bar()


## Updates the info bar hint text based on current state.
func update_info_bar() -> void:
	var zoom_suffix: String = ""
	if not is_equal_approx(current_zoom, 1.0):
		var pct: int = roundi(current_zoom * 100.0)
		zoom_suffix = "   |   Zoom: %d%%" % pct

	if shape_tool_active:
		var hint: String = "oval" if shape_sub_mode == "oval" else "circle"
		info_bar.text = "Click the canvas to place a %s" % hint + zoom_suffix
	elif select_mode_active and not selected_set.is_empty():
		info_bar.text = "Drag handles to resize" + zoom_suffix
	elif select_mode_active:
		info_bar.text = "Click to select an oval" + zoom_suffix
	else:
		info_bar.text = zoom_suffix.trim_prefix("   |   ")
		if info_bar.text.is_empty():
			info_bar.text = ""


## Toggles the grid on/off. Accessible for UI button connections.
func toggle_grid() -> void:
	grid_background.set("grid_enabled", not grid_background.get("grid_enabled"))


# ----- Zoom Controls Relay ---------------------------------------------------

## Relays zoom-in button press to the camera controller.
func _on_zoom_in_requested() -> void:
	var vp_center: Vector2 = _viewport.get_visible_rect().size / 2.0
	camera_controller.call("zoom_by_factor", 1.25, vp_center)


## Relays zoom-out button press to the camera controller.
func _on_zoom_out_requested() -> void:
	var vp_center: Vector2 = _viewport.get_visible_rect().size / 2.0
	camera_controller.call("zoom_by_factor", 0.8, vp_center)


## Relays zoom-reset button press to the camera controller.
func _on_zoom_reset_requested() -> void:
	camera_controller.call("reset_zoom")


## Updates the cached zoom level and refreshes the info bar.
func _on_zoom_changed(level: float) -> void:
	current_zoom = level
	update_info_bar()
