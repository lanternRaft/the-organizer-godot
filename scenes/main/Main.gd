extends Node

## Root controller of the app. Owns the canvas, camera, UI, and input dispatch.

## Preload LabelShape scene for instantiation.
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")

## Whether oval-placement mode is currently active.
var oval_mode_active: bool = false

## Whether select mode is currently active.
var select_mode_active: bool = false

## Reference to the last placed shape (useful for future undo / selection).
var last_placed: Node2D = null

## Whether the grid is currently visible.
var grid_enabled: bool = true

## Currently selected ovals.
var selected_set: Array[LabelShape] = []

## Last-clicked (primary) selection.
var primary_selection: LabelShape = null

@onready var element_layer: Node2D = %ElementLayer
@onready var info_bar: Label = %InfoBar
@onready var canvas: Node2D = %Canvas
@onready var oval_button: Button = $UI/Toolbar/HBox/OvalButton
@onready var select_button: Button = $UI/Toolbar/HBox/SelectButton
@onready var click_handler: Node = $ClickHandler
@onready var confirm_dialog: AcceptDialog = $UI/ConfirmDialog
@onready var grid_background: ColorRect = %GridBackground


func _ready() -> void:
	## Clip canvas rendering to the viewport bounds.
	canvas.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
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


func _unhandled_input(event: InputEvent) -> void:
	## Handle Escape to deactivate Oval mode or clear selection.
	## Keyboard-only — all pointer input is handled by ClickHandler.
	if event.is_action_pressed("ui_cancel"):
		if oval_mode_active:
			deactivate_oval_mode()
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


## Creates a new oval at the given world position and parents it to ElementLayer.
## After placement, auto-switches to Select mode and selects the new oval.
func place_oval(pos: Vector2) -> void:
	var shape: LabelShape = LABEL_SHAPE_SCENE.instantiate() as LabelShape
	shape.position = pos
	element_layer.add_child(shape)
	last_placed = shape

	# Connect the click signal for selection.
	shape.clicked.connect(_on_shape_clicked)
	# Auto-switch to Select mode and select the new shape.
	deactivate_oval_mode()
	activate_select_mode()
	select_shape(shape, false)
	set_primary_selection(shape)


## Activates oval-placement mode. Deactivates Select mode if active.
func activate_oval_mode() -> void:
	if select_mode_active:
		deactivate_select_mode()

	oval_mode_active = true
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	oval_button.button_pressed = true
	select_button.button_pressed = false
	update_info_bar()


## Deactivates oval-placement mode and returns to neutral state.
func deactivate_oval_mode() -> void:
	oval_mode_active = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	oval_button.button_pressed = false
	update_info_bar()


## Activates Select mode. Deactivates Oval mode if active.
func activate_select_mode() -> void:
	if oval_mode_active:
		deactivate_oval_mode()

	select_mode_active = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	select_button.button_pressed = true
	oval_button.button_pressed = false
	update_info_bar()


## Deactivates Select mode and clears selection.
func deactivate_select_mode() -> void:
	select_mode_active = false
	clear_selection()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	select_button.button_pressed = false
	update_info_bar()


## Toggles Oval mode on/off. Connected to Toolbar's signal.
func _on_oval_mode_toggled(active: bool) -> void:
	if active:
		activate_oval_mode()
	else:
		deactivate_oval_mode()


## Toggles Select mode on/off. Connected to Toolbar's signal.
func _on_select_mode_toggled(active: bool) -> void:
	if active:
		activate_select_mode()
	else:
		deactivate_select_mode()


## Called by ClickHandler when a pointer-down lands on empty canvas.
## Routes to the appropriate mode action (placement, selection clear).
func _on_empty_canvas_clicked(world_pos: Vector2) -> void:
	if oval_mode_active:
		place_oval(world_pos)
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
	if oval_mode_active:
		info_bar.text = "Click the canvas to place an oval"
	elif select_mode_active and not selected_set.is_empty():
		info_bar.text = "Drag handles to resize"
	elif select_mode_active:
		info_bar.text = "Click to select an oval"
	else:
		info_bar.text = ""


## Toggles the grid on/off. Accessible for UI button connections.
func toggle_grid() -> void:
	grid_background.set("grid_enabled", not grid_background.get("grid_enabled"))
