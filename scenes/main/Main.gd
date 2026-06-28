extends Node

## Root controller of the app. Owns the canvas, camera, UI, and input dispatch.

## Preload LabelShape and CanvasNode scenes for instantiation.
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
const CANVAS_NODE_SCENE: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")
const TEXT_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/text_edit_overlay/text_edit_overlay.tscn")
const LEGEND_PANEL_SCENE: PackedScene = preload("res://scenes/ui/legend_panel/legend_panel.tscn")

## Path where the canvas state is persisted.
const SAVE_PATH: String = "user://canvas.save"

## Whether shape-placement mode is currently active.
var shape_tool_active: bool = false

## Current shape sub-mode: "oval" or "circle".
var shape_sub_mode: String = "oval"

## Whether node-placement mode is currently active.
var node_tool_active: bool = false

## Current node sub-mode: "circle_node" or "triangle_node".
var node_sub_mode: String = "circle_node"

## Whether select mode is currently active.
var select_mode_active: bool = false

## Reference to the last placed shape (useful for future undo / selection).
var last_placed: Node2D = null

## Most recent zoom level (cached from camera_controller signal).
var current_zoom: float = 1.0

## Whether the grid is currently visible.
var grid_enabled: bool = true

## Current multi-selection set. Contains LabelShape, CanvasNode, and/or Arrow nodes.
## Replaces the old split state (selected_set + selected_arrow).
var selected_set: Array[Node] = []

## Last-clicked (primary) selection. Determines which element gets the stronger highlight.
## Set to the most recently clicked element.
var primary_selection: Node = null

@onready var element_layer: Node2D = %ElementLayer
@onready var info_bar: Label = %InfoBar
@onready var canvas: Node2D = %Canvas
@onready var select_button: Button = $UI/Toolbar/HBox/SelectButton
@onready var click_handler: Node = $ClickHandler
@onready var confirm_dialog: AcceptDialog = $UI/ConfirmDialog
@onready var grid_background: ColorRect = %GridBackground
@onready var camera_controller: Node = $CameraController
@onready var zoom_controls: Control = $UI/ZoomControls
@onready var arrow_manager: Node = $ArrowManager
@onready var _viewport: Viewport = get_viewport()
@onready var ui_layer: CanvasLayer = $UI
@onready var _main_camera: Camera2D = %MainCamera
@onready var _text_overlay: TextEditOverlay = TEXT_OVERLAY_SCENE.instantiate()
@onready var selection_menu: Node = $UI/SelectionMenu
@onready var grid_toggle: Control = $UI/GridToggle
@onready var legend_panel: Control = LEGEND_PANEL_SCENE.instantiate()


func _ready() -> void:
	## Connect ClickHandler's empty-canvas signal for mode-specific actions.
	click_handler.connect("empty_canvas_clicked", _on_empty_canvas_clicked)
	## Connect ClickHandler's pointer-up signal (used by ArrowManager to end arrow drags).
	click_handler.connect("pointer_up", _on_pointer_up)
	## Start in Select mode by default.
	activate_select_mode()

	## Connect grid toggle signal.
	grid_background.connect("grid_toggled", _on_grid_toggled)

	## Load persisted grid state — it loads inside grid_background._ready().
	grid_enabled = grid_background.get("grid_enabled")
	## Sync the toggle button's visual state.
	grid_toggle.call("set_grid_visible", grid_enabled)

	## Set initial theme (dark) on the grid.
	grid_background.call("set_theme_dark", true)

	## Connect zoom controls to camera controller (string-based to bypass type inference).
	zoom_controls.connect("zoom_in_requested", _on_zoom_in_requested)
	zoom_controls.connect("zoom_out_requested", _on_zoom_out_requested)
	zoom_controls.connect("zoom_reset_requested", _on_zoom_reset_requested)

	## Track zoom changes for the info bar.
	camera_controller.connect("zoom_changed", _on_zoom_changed)
	camera_controller.connect("camera_moved", _on_camera_moved)

	## --- Selection Menu Setup ---
	selection_menu.connect("delete_requested", _on_menu_delete_requested)
	selection_menu.connect("color_selected", _on_menu_color_selected)
	camera_controller.connect("zoom_changed", _on_menu_zoom_changed)

	## --- Text Edit Overlay Setup ---
	ui_layer.add_child(_text_overlay)
	_text_overlay.text_committed.connect(_on_text_committed)
	_text_overlay.text_cancelled.connect(_on_text_cancelled)

	## --- Legend Panel Setup ---
	ui_layer.add_child(legend_panel)
	legend_panel.connect("name_changed", _on_legend_name_changed)

	## Load persisted canvas state.
	load_canvas()
	_refresh_legend()


func _unhandled_input(event: InputEvent) -> void:
	## Handle Escape to deactivate Oval/Node mode or clear selection.
	## Keyboard-only — all pointer input is handled by ClickHandler.
	if event.is_action_pressed("ui_cancel"):
		# If text overlay is open, cancel it first.
		if _text_overlay.get("is_open"):
			_text_overlay.call("cancel")
			get_viewport().set_input_as_handled()
			return
		if shape_tool_active:
			deactivate_shape_mode()
			get_viewport().set_input_as_handled()
			return
		if node_tool_active:
			deactivate_node_mode()
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

	## Delete/Backspace key removes the selected arrow or shape.
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return

		if key_event.keycode == KEY_DELETE or key_event.keycode == KEY_BACKSPACE:
			# If editing text, let the overlay handle the key.
			if _text_overlay.get("is_open"):
				return
			if not selected_set.is_empty():
				_delete_selected_elements()
				get_viewport().set_input_as_handled()
				return

		# Ctrl+A or Cmd+A — Select all elements on canvas.
		if (key_event.ctrl_pressed or key_event.meta_pressed) and key_event.keycode == KEY_A:
			_select_all_elements()
			get_viewport().set_input_as_handled()
			return

		# Enter key opens text editor on selected shape.
		# (must come after the Delete check since both dispatch on the same event type)
		if not key_event.ctrl_pressed and not key_event.shift_pressed and not key_event.meta_pressed:
			if key_event.keycode == KEY_ENTER:
				if select_mode_active and primary_selection != null and not _text_overlay.get("is_open"):
					if primary_selection is LabelShape:
						open_text_editor(primary_selection as LabelShape)
						get_viewport().set_input_as_handled()
						return

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
	# Close text overlay if open (the shape being edited may be deleted).
	if _text_overlay.get("is_open"):
		_text_overlay.call("cancel")
	arrow_manager.call("delete_all_arrows")
	for child: Node in element_layer.get_children():
		if child.is_in_group("arrows"):
			continue  # Already removed above.
		child.queue_free()
	clear_selection()
	legend_panel.call("clear_all")
	update_info_bar()


## Opens the confirmation dialog when the hamburger Clear item is selected.
func _on_hamburger_clear_requested() -> void:
	confirm_dialog.popup_centered()


## Called when the Clear button in the confirmation dialog is pressed.
func _on_confirm_dialog_confirmed() -> void:
	clear_all_elements()
	save_canvas()


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
	# Connect double-click for text editing.
	shape.double_clicked.connect(_on_shape_double_clicked)
	# Connect anchor_changed so ArrowManager updates connected arrows.
	shape.anchor_changed.connect(_on_shape_anchor_changed.bind(shape))
	shape.multi_drag_moved.connect(_on_multi_drag_moved.bind(shape))
	shape.multi_drag_ended.connect(_on_multi_drag_ended.bind(shape))
	# Auto-switch to Select mode and select the new shape.
	deactivate_shape_mode()
	activate_select_mode()
	select_element(shape, false)
	set_primary_selection(shape)
	# Save after placement.
	save_canvas()
	_refresh_legend()


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


## Activates node-placement mode with the given sub-mode.
## Deactivates Select mode and Shape mode if active.
func activate_node_mode(sub_mode: String) -> void:
	if select_mode_active:
		deactivate_select_mode()
	if shape_tool_active:
		deactivate_shape_mode()

	node_tool_active = true
	node_sub_mode = sub_mode
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	update_info_bar()


## Deactivates node-placement mode and returns to neutral state.
func deactivate_node_mode() -> void:
	node_tool_active = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	update_info_bar()


## Creates a new CanvasNode at the given world position and parents it to ElementLayer.
## The node's sub-mode is determined by the current node_sub_mode.
## After placement, auto-switches to Select mode and selects the new node.
func place_node(world_pos: Vector2) -> void:
	var node: Node2D = CANVAS_NODE_SCENE.instantiate() as Node2D
	node.set("sub_mode", node_sub_mode)
	node.position = world_pos
	element_layer.add_child(node)
	last_placed = node

	# Connect signals for selection.
	node.connect("clicked", _on_node_clicked)
	# Connect anchor_changed so ArrowManager updates connected arrows.
	node.connect("anchor_changed", _on_node_anchor_changed.bind(node))
	node.connect("multi_drag_moved", _on_multi_drag_moved.bind(node))
	node.connect("multi_drag_ended", _on_multi_drag_ended.bind(node))
	# Auto-switch to Select mode and select the new node.
	deactivate_node_mode()
	activate_select_mode()
	select_element(node, false)
	set_primary_selection(node)
	# Save after placement.
	save_canvas()


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


## Toggles Node mode on/off with the given sub-mode. Connected to Toolbar's signal.
func _on_node_sub_mode_changed(sub_mode: String) -> void:
	activate_node_mode(sub_mode)


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
	elif node_tool_active:
		place_node(world_pos)
	elif select_mode_active and not Input.is_key_pressed(KEY_SHIFT):
		clear_selection()


## Handles a click on a shape. Connected to LabelShape.clicked signal.
## Shift-click toggles additive; single click re-selects.
func _on_shape_clicked(_event: InputEvent, shape: Node) -> void:
	if not select_mode_active:
		return
	_handle_element_clicked(shape)


## Handles a click on a node. Connected to CanvasNode.clicked signal.
## Shift-click toggles additive; single click re-selects.
func _on_node_clicked(_event: InputEvent, node: Node) -> void:
	if not select_mode_active:
		return
	_handle_element_clicked(node)


## Unified click handler for both shapes and arrows.
## Shift-click toggles additive; no-Shift clears and selects just this element.
func _handle_element_clicked(element: Node) -> void:
	if not select_mode_active:
		return

	var shift: bool = Input.is_key_pressed(KEY_SHIFT)

	if shift:
		if element in selected_set:
			_deselect_element(element)
		else:
			select_element(element, true)
			set_primary_selection(element)
	else:
		# No-Shift: clear multi-set and select just this element.
		clear_selection()
		select_element(element, false)
		set_primary_selection(element)


## Adds the element (LabelShape or Arrow) to the selection set.
## If additive is false, clears first.
func select_element(element: Node, additive: bool = false) -> void:
	if not additive:
		clear_selection()
	if not element in selected_set:
		selected_set.append(element)
	# Duck-type: both LabelShape and Arrow have set_selected / is_selected.
	if element.has_method(&"set_selected"):
		element.call("set_selected", true)
	_refresh_primary_visuals()
	_update_selection_menu()
	update_info_bar()


## Removes the element from the selection set.
func _deselect_element(element: Node) -> void:
	if element.has_method(&"set_selected"):
		element.call("set_selected", false)
	selected_set.erase(element)
	if primary_selection == element:
		if selected_set.is_empty():
			primary_selection = null
		else:
			primary_selection = selected_set[-1]
	_refresh_primary_visuals()
	_update_selection_menu()
	update_info_bar()


## Sets the primary (last-clicked) selection and refreshes visual priority indicators.
func set_primary_selection(element: Node) -> void:
	primary_selection = element
	_refresh_primary_visuals()
	_update_selection_menu()


## Refreshes is_primary on every element in selected_set so the primary element
## gets stronger highlight and secondary elements get dimmer highlight.
func _refresh_primary_visuals() -> void:
	for elem: Node in selected_set:
		if elem.has_method(&"set"):
			elem.set("is_primary", elem == primary_selection)


## Clears all selection.
func clear_selection() -> void:
	for elem: Node in selected_set:
		if not is_instance_valid(elem):
			continue
		if elem.has_method(&"set_selected"):
			elem.call("set_selected", false)
	selected_set.clear()
	primary_selection = null
	selection_menu.call("dismiss")
	update_info_bar()


## Updates the info bar hint text based on current state.
func update_info_bar() -> void:
	var zoom_suffix: String = ""
	if not is_equal_approx(current_zoom, 1.0):
		var pct: int = roundi(current_zoom * 100.0)
		zoom_suffix = "   |   Zoom: %d%%" % pct

	if _text_overlay.get("is_open"):
		info_bar.text = "Type your text   Enter to confirm   Escape to cancel" + zoom_suffix
	elif shape_tool_active:
		var hint: String = "oval" if shape_sub_mode == "oval" else "circle"
		info_bar.text = "Click the canvas to place a %s" % hint + zoom_suffix
	elif node_tool_active:
		var hint: String = "circle" if node_sub_mode == "circle_node" else "triangle"
		info_bar.text = "Click the canvas to place a %s node" % hint + zoom_suffix
	elif select_mode_active and not selected_set.is_empty():
		if selected_set.size() > 1:
			info_bar.text = "Drag to move %d selected elements" % selected_set.size() + zoom_suffix
		else:
			if primary_selection is Node2D and primary_selection.has_method("get_anchor_points"):
				info_bar.text = "Drag to move   Click color to change" + zoom_suffix
			else:
				info_bar.text = "Enter to edit text   Drag handles to resize" + zoom_suffix
	elif select_mode_active:
		info_bar.text = "Click to select an oval" + zoom_suffix
	else:
		info_bar.text = zoom_suffix.trim_prefix("   |   ")
		if info_bar.text.is_empty():
			info_bar.text = ""


## Toggles the grid on/off. Accessible for UI button connections.
func toggle_grid() -> void:
	grid_background.set("grid_enabled", not grid_background.get("grid_enabled"))
	grid_toggle.call("set_grid_visible", grid_background.get("grid_enabled"))


# ----- Text Editing ----------------------------------------------------------

## Opens the text edit overlay centered over the given shape.
func open_text_editor(shape: LabelShape) -> void:
	# Guard: shape must still be in the tree.
	if not is_instance_valid(shape) or not shape.is_inside_tree():
		return

	var shape_center: Vector2 = shape.global_position
	var screen_pos: Vector2 = (_main_camera as Camera2D).get_canvas_transform() * shape_center

	# Calculate overlay size to match shape visual bounds × zoom, with a minimum.
	var overlay_width: float = max(160.0, shape.rx * 2.0 * current_zoom)
	var overlay_height: float = max(80.0, shape.ry * 2.0 * current_zoom)

	var screen_rect: Rect2 = Rect2(
		screen_pos - Vector2(overlay_width / 2.0, overlay_height / 2.0),
		Vector2(overlay_width, overlay_height)
	)

	_text_overlay.call("open", shape, screen_rect)
	_update_selection_menu()
	update_info_bar()


## Called when a shape is double-clicked. Opens the text editor.
func _on_shape_double_clicked(shape: Node) -> void:
	if not select_mode_active:
		return
	var label_shape: LabelShape = shape as LabelShape
	if label_shape == null:
		return
	open_text_editor(label_shape)


## Called when text is committed in the overlay. Triggers persistence save.
func _on_text_committed(shape: Node, text: String) -> void:
	if is_instance_valid(shape):
		var label_shape: LabelShape = shape as LabelShape
		if label_shape != null:
			label_shape.text_content = text
	save_canvas()
	_update_selection_menu()
	update_info_bar()


## Called when text editing is cancelled. No changes are saved.
func _on_text_cancelled(_shape: Node) -> void:
	_update_selection_menu()
	update_info_bar()


# ----- Persistence -----------------------------------------------------------

## Serialises all canvas elements into a Dictionary for save.
func serialize_canvas() -> Dictionary:
	var elements: Array[Dictionary] = []
	for child: Node in element_layer.get_children():
		if child is LabelShape:
			var shape: LabelShape = child as LabelShape
			var pos: Vector2 = shape.position
			var color: Color = shape.fill_color
			elements.append({
				"type": "LabelShape",
				"position_x": pos.x,
				"position_y": pos.y,
				"rx": shape.rx,
				"ry": shape.ry,
				"fill_r": color.r,
				"fill_g": color.g,
				"fill_b": color.b,
				"fill_a": color.a,
				"text": shape.text_content,
				"shape_mode": shape.shape_mode,
			})
		elif child is Node2D and child.has_method("get_anchor_points"):
			var node: Node2D = child as Node2D
			var pos: Vector2 = node.position
			var color: Color = node.get("fill_color")
			elements.append({
				"type": "CanvasNode",
				"position_x": pos.x,
				"position_y": pos.y,
				"fill_r": color.r,
				"fill_g": color.g,
				"fill_b": color.b,
				"fill_a": color.a,
				"sub_mode": node.get("sub_mode"),
			})
	var result: Dictionary = {"elements": elements}
	result["legend"] = legend_panel.call("get_legend_data")
	return result


## Saves the current canvas state to disk.
func save_canvas() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: ", SAVE_PATH)
		return
	file.store_var(serialize_canvas())


## Loads the canvas state from disk (called during _ready).
func load_canvas() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: ", SAVE_PATH)
		return
	var data: Dictionary = file.get_var()

	# Restore legend data first (before loading elements).
	if data.has("legend"):
		var legend_data: Variant = data["legend"]
		if typeof(legend_data) == TYPE_ARRAY:
			legend_panel.call("load_legend_data", legend_data)

	for element_data: Variant in data.get("elements", []):
		if typeof(element_data) == TYPE_DICTIONARY:
			var elem: Dictionary = element_data
			if elem.get("type") == "LabelShape":
				_load_label_shape(elem)
			elif elem.get("type") == "CanvasNode":
				_load_canvas_node(elem)


## Instantiates a LabelShape from serialised data and adds it to the canvas.
func _load_label_shape(data: Dictionary) -> void:
	var shape: LabelShape = LABEL_SHAPE_SCENE.instantiate()
	@warning_ignore("unsafe_cast")
	shape.position = Vector2(data.get("position_x", 0.0) as float, data.get("position_y", 0.0) as float)
	@warning_ignore("unsafe_cast")
	shape.rx = data.get("rx", 80.0) as float
	@warning_ignore("unsafe_cast")
	shape.ry = data.get("ry", 50.0) as float
	@warning_ignore("unsafe_cast")
	shape.fill_color = Color(data.get("fill_r", 0.231) as float, data.get("fill_g", 0.51) as float, data.get("fill_b", 0.965) as float, data.get("fill_a", 1.0) as float)
	shape.shape_mode = str(data.get("shape_mode", "oval"))
	shape.text_content = str(data.get("text", ""))

	element_layer.add_child(shape)
	shape.clicked.connect(_on_shape_clicked)
	shape.double_clicked.connect(_on_shape_double_clicked)
	shape.anchor_changed.connect(_on_shape_anchor_changed.bind(shape))
	shape.multi_drag_moved.connect(_on_multi_drag_moved.bind(shape))
	shape.multi_drag_ended.connect(_on_multi_drag_ended.bind(shape))


## Instantiates a CanvasNode from serialised data and adds it to the canvas.
func _load_canvas_node(data: Dictionary) -> void:
	var node: Node2D = CANVAS_NODE_SCENE.instantiate()
	var px: float = data.get("position_x", 0.0)
	var py: float = data.get("position_y", 0.0)
	node.position = Vector2(px, py)
	var fr: float = data.get("fill_r", 0.231)
	var fg: float = data.get("fill_g", 0.51)
	var fb: float = data.get("fill_b", 0.965)
	var fa: float = data.get("fill_a", 1.0)
	node.set("fill_color", Color(fr, fg, fb, fa))
	node.set("sub_mode", str(data.get("sub_mode", "circle_node")))

	element_layer.add_child(node)
	node.connect("clicked", _on_node_clicked)
	node.connect("anchor_changed", _on_node_anchor_changed.bind(node))
	node.connect("multi_drag_moved", _on_multi_drag_moved.bind(node))
	node.connect("multi_drag_ended", _on_multi_drag_ended.bind(node))


# ----- Multi-Drag Coordination ------------------------------------------------

## Called when a selected element moves during a drag. Broadcasts the same delta
## to every other element in selected_set so they all move in sync.
## The emitter element already handled its own movement — this only moves siblings.
func _on_multi_drag_moved(delta: Vector2, emitter: Node) -> void:
	if selected_set.size() <= 1:
		return
	for elem: Node in selected_set:
		if elem == emitter:
			continue
		if elem is LabelShape:
			var shape: LabelShape = elem as LabelShape
			shape.position += delta
			shape.anchor_changed.emit()
		elif elem is Node2D and elem.has_method("get_anchor_points"):
			var node: Node2D = elem as Node2D
			node.position += delta
			node.emit_signal("anchor_changed")
		elif elem.is_in_group("arrows"):
			var arrow_node: Node = elem
			if arrow_node is Node2D:
				(arrow_node as Node2D).position += delta


## Called when a body-drag ends on a LabelShape or CanvasNode. Snaps all other selected
## elements to the 20px grid so they stay aligned with the dragged element.
func _on_multi_drag_ended(_emitter: Node) -> void:
	if selected_set.size() <= 1:
		return
	for elem: Node in selected_set:
		if elem is LabelShape:
			var shape: LabelShape = elem as LabelShape
			shape.position = shape.position.snapped(Vector2(20.0, 20.0))
			shape.anchor_changed.emit()
		elif elem is Node2D and elem.has_method("get_anchor_points"):
			var node: Node2D = elem as Node2D
			node.position = node.position.snapped(Vector2(20.0, 20.0))
			node.emit_signal("anchor_changed")


## Selects all LabelShapes, CanvasNodes, and Arrows currently on the canvas.
func _select_all_elements() -> void:
	if not select_mode_active:
		return
	clear_selection()
	for child: Node in element_layer.get_children():
		if child is LabelShape or (child is Node2D and child.has_method("get_anchor_points")) or child.is_in_group("arrows"):
			select_element(child, true)
	if not selected_set.is_empty():
		set_primary_selection(selected_set[-1])


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


# ----- Arrow System Interface ------------------------------------------------

## Called by ClickHandler as a secondary path when no Area2D shape was hit.
## Checks whether the click is on an arrow path. Returns true if consumed.
## Uses unified selection logic (Shift+click additive, no-Shift replace).
func _on_arrow_clicked_at(world_pos: Vector2) -> bool:
	if not select_mode_active:
		return false
	if arrow_manager == null:
		return false
	var arrow: Variant = arrow_manager.call("get_arrow_near", world_pos)
	if arrow != null:
		@warning_ignore("unsafe_cast")
		var arrow_node: Node = arrow as Node
		if arrow_node != null:
			_handle_element_clicked(arrow_node)
		return true
	return false


## Called by ClickHandler as a secondary path after arrow check fails.
## Checks whether the click is on an anchor dot (to begin arrow drag).
func _on_anchor_dot_mousedown(world_pos: Vector2) -> bool:
	if not select_mode_active:
		return false
	if arrow_manager == null:
		return false
	return arrow_manager.call("handle_dot_mousedown", world_pos)


## Called by ClickHandler's pointer_up signal to notify ArrowManager.
func _on_pointer_up(_world_pos: Vector2) -> void:
	if arrow_manager == null:
		return
	arrow_manager.call("handle_dot_mouseup")


## Called by Main when a shape emits anchor_changed (resized or moved).
func _on_shape_anchor_changed(shape: LabelShape) -> void:
	if arrow_manager == null:
		return
	arrow_manager.call("update_arrows_for_shape", shape)


## Called by Main when a node emits anchor_changed (moved).
func _on_node_anchor_changed(node: Node2D) -> void:
	if arrow_manager == null:
		return
	arrow_manager.call("update_arrows_for_shape", node)


# ----- Selection Menu & Deletion ---------------------------------------------

## Shows/hides the selection menu based on current selection state.
## Menu is hidden entirely when more than one element is selected.
func _update_selection_menu() -> void:
	if not select_mode_active:
		selection_menu.call("dismiss")
		return
	if _text_overlay.get("is_open"):
		selection_menu.call("dismiss")
		return
	if selected_set.size() == 1 and primary_selection != null:
		selection_menu.call("show_for_element", primary_selection)
	else:
		selection_menu.call("dismiss")


## Deletes the currently selected element via the menu's Delete button.
func _on_menu_delete_requested() -> void:
	if not selected_set.is_empty():
		_delete_selected_elements()


## Deletes all elements currently in the selection set.
## Iterates a duplicate so modifying the original doesn't cause issues.
func _delete_selected_elements() -> void:
	var to_delete: Array[Node] = selected_set.duplicate()
	for element: Node in to_delete:
		if not is_instance_valid(element):
			selected_set.erase(element)
			continue
		if element is LabelShape:
			var shape: LabelShape = element as LabelShape
			if shape == null:
				continue
			selected_set.erase(shape)
			if primary_selection == shape:
				primary_selection = null
			_delete_shape_element(shape)
		elif element is Node2D and element.has_method("get_anchor_points"):
			var node: Node2D = element as Node2D
			if node == null:
				continue
			selected_set.erase(node)
			if primary_selection == node:
				primary_selection = null
			_delete_node_element(node)
		elif element.is_in_group("arrows"):
			selected_set.erase(element)
			if primary_selection == element:
				primary_selection = null
			arrow_manager.call("delete_arrow", element)
	clear_selection()
	save_canvas()
	# Legend refresh uses only LabelShape colors, so deletion of nodes doesn't affect it.
	# But we still call it in case a shape was deleted.
	_refresh_legend()


## Removes a LabelShape and any connected arrows from the canvas and selection.
func _delete_shape_element(shape: LabelShape) -> void:
	if not is_instance_valid(shape):
		return
	arrow_manager.call("delete_arrows_for_shape", shape)
	selected_set.erase(shape)
	if primary_selection == shape:
		primary_selection = null
	shape.queue_free()
	_update_selection_menu()
	update_info_bar()


## Removes a CanvasNode and any connected arrows from the canvas and selection.
func _delete_node_element(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	arrow_manager.call("delete_arrows_for_shape", node)
	selected_set.erase(node)
	if primary_selection == node:
		primary_selection = null
	node.queue_free()
	_update_selection_menu()
	update_info_bar()


## Applies the selected color from the palette to the currently selected element.
func _on_menu_color_selected(color: Color) -> void:
	if primary_selection != null and selected_set.size() == 1:
		if primary_selection is LabelShape:
			var shape: LabelShape = primary_selection as LabelShape
			shape.fill_color = color
			save_canvas()
			_refresh_legend()
		elif primary_selection is Node2D and primary_selection.has_method("get_anchor_points"):
			var node: Node2D = primary_selection as Node2D
			node.set("fill_color", color)
			save_canvas()


## Legend Panel ---------------------------------------------------------------

## Scans the canvas for unique fill colors from LabelShapes and updates the legend panel.
## CanvasNode colors are intentionally excluded — nodes are decorative markers, not categories.
## Called after any color-affecting mutation (placement, recolor, deletion, clear).
func _refresh_legend() -> void:
	var colors: Array[Color] = []
	for child: Node in element_layer.get_children():
		if child is LabelShape:
			var shape: LabelShape = child as LabelShape
			colors.append(shape.fill_color)
	legend_panel.call("set_colors_in_use", colors)


## Called when the user edits a legend label. Saves the canvas to persist the name.
func _on_legend_name_changed(_color: Color, _new_name: String) -> void:
	save_canvas()


## Repositions the selection menu when the camera zooms.
func _on_menu_zoom_changed(_level: float) -> void:
	selection_menu.call("refresh_position")


## Called when the camera moves (pan, cursor-centered zoom, or reset).
## Refreshes the selection menu and text overlay so they follow the element on screen.
func _on_camera_moved() -> void:
	selection_menu.call("refresh_position")
	if _text_overlay.get("is_open"):
		_text_overlay.call("reposition", _main_camera, current_zoom)
