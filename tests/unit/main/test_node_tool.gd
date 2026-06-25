# GdUnit generated TestSuite
class_name NodeToolTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/main/main.gd'
const __scene: PackedScene = preload("res://scenes/main/main.tscn")

const CANVAS_NODE_SCENE: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
const LEGEND_PANEL_SCENE: PackedScene = preload("res://scenes/ui/legend_panel/legend_panel.tscn")

# ----- Helpers ---------------------------------------------------------------

## Creates a minimal Main-like test environment.
## Since main.tscn has many UI children that aren't needed for node tool tests,
## we create a minimal Node with Main.gd's script and add only the required
## sub-nodes. This avoids loading entire UI scenes while still exercising
## the node tool integration paths.
##
## Returns { "main": Node, "element_layer": Node2D, "info_bar": Label, "arrow_manager": Node, ... }
func _create_main_env() -> Dictionary:
	var main: Node = Node.new()
	main.set_script(load("res://scenes/main/main.gd"))
	get_tree().root.add_child(main)

	# Add required child nodes that Main's @onready vars reference.
	# Canvas
	var canvas: Node2D = Node2D.new()
	canvas.name = "Canvas"
	canvas.unique_name_in_owner = true
	main.add_child(canvas)

	# ElementLayer (under Canvas)
	var element_layer: Node2D = Node2D.new()
	element_layer.name = "ElementLayer"
	element_layer.unique_name_in_owner = true
	canvas.add_child(element_layer)

	# AnchorLayer (under Canvas)
	var anchor_layer: Node2D = Node2D.new()
	anchor_layer.name = "AnchorLayer"
	anchor_layer.unique_name_in_owner = true
	canvas.add_child(anchor_layer)

	# GridBackground stub (under Canvas/GridLayer)
	var grid_layer: CanvasLayer = CanvasLayer.new()
	grid_layer.name = "GridLayer"
	grid_layer.unique_name_in_owner = true
	canvas.add_child(grid_layer)
	var grid_bg: ColorRect = ColorRect.new()
	grid_bg.name = "GridBackground"
	grid_bg.unique_name_in_owner = true
	grid_layer.add_child(grid_bg)
	grid_bg.set_script(load("res://scenes/main/grid/grid_background.gd"))

	# UI CanvasLayer
	var ui_layer: CanvasLayer = CanvasLayer.new()
	ui_layer.name = "UI"
	main.add_child(ui_layer)

	# InfoBar (under UI)
	var info_bar: Label = Label.new()
	info_bar.name = "InfoBar"
	info_bar.unique_name_in_owner = true
	ui_layer.add_child(info_bar)

	# SelectionMenu stub (under UI)
	var sel_menu: Control = Control.new()
	sel_menu.name = "SelectionMenu"
	sel_menu.set_script(load("res://scenes/ui/selection_menu/selection_menu.gd"))
	ui_layer.add_child(sel_menu)

	# HamburgerMenu stub (under UI) — we just need it so the node path doesn't fail
	var hm: Control = Control.new()
	hm.name = "HamburgerMenu"
	ui_layer.add_child(hm)

	# ConfirmDialog stub (under UI)
	var confirm: AcceptDialog = AcceptDialog.new()
	confirm.name = "ConfirmDialog"
	ui_layer.add_child(confirm)

	# ZoomControls stub (under UI)
	var zoom: Control = Control.new()
	zoom.name = "ZoomControls"
	zoom.set_script(load("res://scenes/ui/zoom_controls/zoom_controls.gd"))
	ui_layer.add_child(zoom)

	# GridToggle stub (under UI)
	var gt: Control = Control.new()
	gt.name = "GridToggle"
	ui_layer.add_child(gt)

	# Toolbar stub (under UI)
	var toolbar: Control = Control.new()
	toolbar.name = "Toolbar"
	ui_layer.add_child(toolbar)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "HBox"
	toolbar.add_child(hbox)
	var select_btn: Button = Button.new()
	select_btn.name = "SelectButton"
	select_btn.toggle_mode = true
	hbox.add_child(select_btn)

	# Toolbar also needs a script for node_sub_mode_changed signal, but we can
	# simulate that by calling _on_node_sub_mode_changed directly.

	# ClickHandler
	var click_handler: Node = Node.new()
	click_handler.name = "ClickHandler"
	click_handler.set_script(load("res://scenes/main/click_handler/click_handler.gd"))
	main.add_child(click_handler)

	# CameraController
	var cam_ctrl: Node = Node.new()
	cam_ctrl.name = "CameraController"
	cam_ctrl.set_script(load("res://scenes/main/camera_controller/camera_controller.gd"))
	main.add_child(cam_ctrl)

	# MainCamera
	var camera: Camera2D = Camera2D.new()
	camera.name = "MainCamera"
	camera.unique_name_in_owner = true
	main.add_child(camera)

	# ArrowManager
	var arrow_mgr: Node = Node.new()
	arrow_mgr.name = "ArrowManager"
	arrow_mgr.set_script(load("res://scenes/arrow_manager/arrow_manager.gd"))
	main.add_child(arrow_mgr)
	# Wire up element_layer and anchor_layer references that ArrowManager needs.
	arrow_mgr.set("element_layer", element_layer)
	arrow_mgr.set("anchor_layer", anchor_layer)

	# Add LegendPanel to UI
	var legend_panel: Control = LEGEND_PANEL_SCENE.instantiate()
	ui_layer.add_child(legend_panel)

	# Wait for _ready() to run.
	await get_tree().process_frame

	# After _ready, ensure critical connections are set up.
	# _ready() calls activate_select_mode() which calls deactivate_shape_mode,
	# update_info_bar, etc. — we need the state to be clean.
	# Reset to initial test state.
	main.set("node_tool_active", false)
	main.set("node_sub_mode", "circle_node")
	main.set("shape_tool_active", false)
	main.set("select_mode_active", false)
	main.set("selected_set", [])
	main.set("primary_selection", null)

	return {
		"main": main,
		"element_layer": element_layer,
		"info_bar": info_bar,
		"arrow_manager": arrow_mgr,
		"selection_menu": sel_menu,
		"legend_panel": legend_panel,
		"camera_controller": cam_ctrl,
		"click_handler": click_handler,
	}


## Creates a CanvasNode circle in the given element_layer and returns it.
## Does NOT connect signals — test cases that need signal connections
## should use _create_node_and_connect or call place_node on Main.
func _create_circle_node(el: Node2D, pos: Vector2) -> Node2D:
	var node: Node2D = CANVAS_NODE_SCENE.instantiate()
	node.set("sub_mode", "circle_node")
	node.position = pos
	el.add_child(node)
	return node


## Creates a CanvasNode triangle in the given element_layer and returns it.
func _create_triangle_node(el: Node2D, pos: Vector2) -> Node2D:
	var node: Node2D = CANVAS_NODE_SCENE.instantiate()
	node.set("sub_mode", "triangle_node")
	node.position = pos
	el.add_child(node)
	return node


## Creates a LabelShape oval in the given element_layer and returns it.
func _create_label_shape(el: Node2D, pos: Vector2) -> Node2D:
	var shape: Node2D = LABEL_SHAPE_SCENE.instantiate()
	shape.set("rx", 80.0)
	shape.set("ry", 50.0)
	shape.position = pos
	el.add_child(shape)
	return shape


# ===== C1-C3: Tool Activation ===============================================

## C1: Activate node tool sets correct state.
func test_activate_node_tool() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]

	main.call("activate_node_mode", "circle_node")

	assert_bool(main.get("node_tool_active")).is_true()
	assert_str(main.get("node_sub_mode")).is_equal("circle_node")
	assert_bool(main.get("shape_tool_active")).is_false()
	assert_bool(main.get("select_mode_active")).is_false()
	# Cursor should be crosshair.
	assert_int(Input.get_current_cursor_shape()).is_equal(Input.CURSOR_CROSS)

	env["main"].free()


## C2: Node tool deactivates shape tool.
func test_node_tool_deactivates_shape_tool() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]

	main.call("activate_shape_mode", "oval")
	assert_bool(main.get("shape_tool_active")).is_true()

	main.call("activate_node_mode", "triangle_node")
	assert_bool(main.get("node_tool_active")).is_true()
	assert_bool(main.get("shape_tool_active")).is_false()

	env["main"].free()


## C3: Node tool deactivates select tool.
func test_node_tool_deactivates_select_tool() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]

	main.call("activate_select_mode")
	assert_bool(main.get("select_mode_active")).is_true()

	main.call("activate_node_mode", "circle_node")
	assert_bool(main.get("node_tool_active")).is_true()
	assert_bool(main.get("select_mode_active")).is_false()

	env["main"].free()


# ===== C4-C5: Place Node ====================================================

## C4: Place circle node.
func test_place_circle_node() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(150, 250))

	# A CanvasNode child is added to ElementLayer.
	var children: Array[Node] = el.get_children()
	assert_int(children.size()).is_equal(1)
	var node: Node2D = children[0] as Node2D
	assert_bool(node != null).is_true()

	# Its position = (150, 250).
	assert_vector(node.position).is_equal(Vector2(150, 250))
	# Its sub_mode = "circle_node".
	assert_str(node.get("sub_mode")).is_equal("circle_node")

	# node_tool_active = false (auto-return to select).
	assert_bool(main.get("node_tool_active")).is_false()
	# select_mode_active = true.
	assert_bool(main.get("select_mode_active")).is_true()

	# The node is in selected_set.
	var selected_set: Array = main.get("selected_set")
	assert_bool(node in selected_set).is_true()
	# The node is primary_selection.
	assert_object(main.get("primary_selection")).is_same(node)
	# last_placed = the node.
	assert_object(main.get("last_placed")).is_same(node)

	# Signals connected.
	assert_bool(node.is_connected("clicked", Callable(main, "_on_node_clicked"))).is_true()
	assert_bool(node.is_connected("anchor_changed", Callable(main, "_on_node_anchor_changed").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_moved", Callable(main, "_on_multi_drag_moved").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_ended", Callable(main, "_on_multi_drag_ended").bind(node))).is_true()

	# save_canvas() was called (we verify by checking that the save file was written).
	# The save path is "user://canvas.save".
	var save_path: String = main.get("SAVE_PATH")
	assert_bool(FileAccess.file_exists(save_path)).is_true()

	env["main"].free()


## C5: Place triangle node.
func test_place_triangle_node() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	main.call("activate_node_mode", "triangle_node")
	main.call("place_node", Vector2(300, 100))

	var children: Array[Node] = el.get_children()
	assert_int(children.size()).is_equal(1)
	var node: Node2D = children[0] as Node2D
	assert_str(node.get("sub_mode")).is_equal("triangle_node")
	assert_vector(node.position).is_equal(Vector2(300, 100))
	assert_bool(main.get("node_tool_active")).is_false()
	assert_bool(main.get("select_mode_active")).is_true()

	env["main"].free()


# ===== C6: Empty Canvas Click Routes to place_node ==========================

## C6: Empty canvas click in node mode routes to place_node.
func test_empty_canvas_click_in_node_mode() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Activate node mode.
	main.call("activate_node_mode", "circle_node")
	assert_int(el.get_child_count()).is_equal(0)

	# Simulate empty_canvas_clicked signal from ClickHandler.
	main.call("_on_empty_canvas_clicked", Vector2(200, 200))

	# A node should appear at (200, 200).
	assert_int(el.get_child_count()).is_equal(1)
	var node: Node2D = el.get_child(0) as Node2D
	assert_vector(node.position).is_equal(Vector2(200, 200))

	env["main"].free()


# ===== C7: Escape Exits Node Mode ===========================================

## C7: Escape key exits node mode without placing.
func test_escape_exits_node_mode() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	main.call("activate_node_mode", "circle_node")
	assert_bool(main.get("node_tool_active")).is_true()

	# Simulate Escape key press.
	var escape_event: InputEventKey = InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	main.call("_unhandled_input", escape_event)

	assert_bool(main.get("node_tool_active")).is_false()
	assert_int(el.get_child_count()).is_equal(0)
	assert_int(Input.get_current_cursor_shape()).is_equal(Input.CURSOR_ARROW)

	env["main"].free()


# ===== C8-C10: Node Click Selection =========================================

## C8: Node click selects.
func test_node_click_selects() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Place a node using place_node (which sets up signal connections).
	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(100, 100))

	# Clear selection and switch to select mode.
	main.call("clear_selection")
	main.call("activate_select_mode")
	assert_int((main.get("selected_set") as Array).size()).is_equal(0)

	# Simulate a click on the node via _on_node_clicked.
	var node: Node2D = el.get_child(0)
	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	main.call("_on_node_clicked", dummy_event, node)

	# Node should be in selected_set
	var selected_set: Array = main.get("selected_set")
	assert_bool(node in selected_set).is_true()
	assert_object(main.get("primary_selection")).is_same(node)

	env["main"].free()


## C9: Shift-click adds to multi-select.
func test_node_shift_click_multiselect() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Place two nodes using place_node.
	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(100, 100))
	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(200, 100))

	var node1: Node2D = el.get_child(0)
	var node2: Node2D = el.get_child(1)

	# Clear selection and switch to select mode.
	main.call("clear_selection")
	main.call("activate_select_mode")

	# Click first node (no shift).
	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	main.call("_on_node_clicked", dummy_event, node1)
	assert_int((main.get("selected_set") as Array).size()).is_equal(1)

	# Simulate Shift held by setting KEY_SHIFT in Input state.
	# We'll simulate shift-click by directly calling the handler logic.
	# In a test, we can use Input.parse_input_event, but it's simpler to call
	# _handle_element_clicked with KeyEvent or mock the shift check.
	# Alternatively, just check that _on_node_clicked dispatches correctly.
	# For shift, we need Input.is_key_pressed(KEY_SHIFT) to return true.
	# We can simulate this by creating a shift press first.

	var shift_press: InputEventKey = InputEventKey.new()
	shift_press.keycode = KEY_SHIFT
	shift_press.pressed = true
	Input.parse_input_event(shift_press)

	main.call("_on_node_clicked", dummy_event, node2)

	# Both nodes should now be selected.
	var selected_set: Array = main.get("selected_set")
	assert_int(selected_set.size()).is_equal(2)
	assert_bool(node1 in selected_set).is_true()
	assert_bool(node2 in selected_set).is_true()

	# Info bar shows multi-select message.
	var info_text: String = env["info_bar"].text
	assert_str(info_text).contains("2 selected")

	# Release shift.
	var shift_release: InputEventKey = InputEventKey.new()
	shift_release.keycode = KEY_SHIFT
	shift_release.pressed = false
	Input.parse_input_event(shift_release)

	env["main"].free()


## C10: Node click clears shape selection.
func test_node_click_clears_shape_selection() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Create a shape and add it to the element layer with signal connections
	# (as place_shape would do).
	var shape: Node2D = _create_label_shape(el, Vector2(0, 0))
	shape.connect("clicked", Callable(main, "_on_shape_clicked"))
	# Manually select it.
	main.call("activate_select_mode")
	main.call("select_element", shape, false)
	assert_bool(shape in (main.get("selected_set") as Array)).is_true()

	# Create a node via place_node to get signal connections.
	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(100, 100))

	# Clear selection first to reset state.
	main.call("clear_selection")
	main.call("activate_select_mode")

	# Now select the shape again.
	main.call("select_element", shape, false)
	assert_bool(shape in (main.get("selected_set") as Array)).is_true()

	# Click the node (no shift).
	var node: Node2D = el.get_child(1)
	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	main.call("_on_node_clicked", dummy_event, node)

	# Shape should be deselected; node should be the only selection.
	var selected_set: Array = main.get("selected_set")
	assert_bool(shape in selected_set).is_false()
	assert_bool(node in selected_set).is_true()
	assert_int(selected_set.size()).is_equal(1)

	env["main"].free()


# ===== C11: Node Color Change ===============================================

## C11: Node color change via selection menu.
func test_node_color_change() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]

	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(100, 100))

	# The node is now primary_selection. Change its color.
	main.call("_on_menu_color_selected", Color.RED)

	var node: Node2D = env["element_layer"].get_child(0)
	assert_color(node.get("fill_color")).is_equal(Color.RED)

	# save_canvas() was called.
	var save_path: String = main.get("SAVE_PATH")
	assert_bool(FileAccess.file_exists(save_path)).is_true()

	env["main"].free()


# ===== C12-C13: Delete Node =================================================

## C12: Delete node.
func test_delete_node() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(100, 100))
	var node: Node2D = el.get_child(0)

	# Node is already selected after placement.
	# Simulate Delete key.
	var delete_event: InputEventKey = InputEventKey.new()
	delete_event.keycode = KEY_DELETE
	delete_event.pressed = true
	main.call("_unhandled_input", delete_event)

	# Node removed from element layer.
	assert_int(el.get_child_count()).is_equal(0)
	assert_int((main.get("selected_set") as Array).size()).is_equal(0)
	assert_object(main.get("primary_selection")).is_null()
	# save_canvas() should have been called.
	assert_bool(FileAccess.file_exists(main.get("SAVE_PATH"))).is_true()

	env["main"].free()


## C13: Delete node with connected arrows.
func test_delete_node_with_arrows() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]
	var mgr: Node = env["arrow_manager"]

	# Place a shape.
	main.call("activate_shape_mode", "oval")
	main.call("place_shape", Vector2(0, 0))
	var shape: Node2D = el.get_child(0)

	# Place a node.
	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(200, 0))
	var node: Node2D = el.get_child(1)

	# Create arrow between them.
	mgr.call("_refresh_shape_list")
	mgr.call("_create_arrow", shape, "right", node, "left")
	assert_int((mgr.get("_arrows") as Array).size()).is_equal(1)

	# Clear selection and re-select just the node.
	main.call("clear_selection")
	main.call("activate_select_mode")
	main.call("select_element", node, false)

	# Delete selected elements.
	var delete_event: InputEventKey = InputEventKey.new()
	delete_event.keycode = KEY_DELETE
	delete_event.pressed = true
	main.call("_unhandled_input", delete_event)

	# Node removed.
	assert_int(el.get_child_count()).is_equal(1)  # Only the shape remains.
	# Arrow removed.
	assert_int((mgr.get("_arrows") as Array).size()).is_equal(0)

	env["main"].free()


# ===== C14: Select All Includes Nodes =======================================

## C14: Select all includes nodes.
func test_select_all_includes_nodes() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Create two shapes.
	var shape1: Node2D = _create_label_shape(el, Vector2(0, 0))
	var shape2: Node2D = _create_label_shape(el, Vector2(100, 0))
	# Create one node.
	var node: Node2D = _create_circle_node(el, Vector2(200, 0))

	main.call("activate_select_mode")

	# Simulate Ctrl+A.
	var ctrl_a: InputEventKey = InputEventKey.new()
	ctrl_a.keycode = KEY_A
	ctrl_a.ctrl_pressed = true
	ctrl_a.pressed = true
	main.call("_unhandled_input", ctrl_a)

	var selected_set: Array = main.get("selected_set")
	assert_int(selected_set.size()).is_equal(3)
	assert_bool(shape1 in selected_set).is_true()
	assert_bool(shape2 in selected_set).is_true()
	assert_bool(node in selected_set).is_true()

	env["main"].free()


# ===== C15-C16: Serialization ===============================================

## C15: CanvasNode serialization.
func test_canvas_node_serialization() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Place a circle node at (100, 200) with red fill.
	var node: Node2D = _create_circle_node(el, Vector2(100, 200))
	node.set("fill_color", Color(1.0, 0.0, 0.0, 1.0))

	var data: Dictionary = main.call("serialize_canvas")
	var elements: Array = data.get("elements", [])
	assert_int(elements.size()).is_equal(1)

	var entry: Dictionary = elements[0]
	assert_str(entry.get("type")).is_equal("CanvasNode")
	assert_float(entry.get("position_x") as float).is_equal_approx(100.0, 0.1)
	assert_float(entry.get("position_y") as float).is_equal_approx(200.0, 0.1)
	assert_float(entry.get("fill_r") as float).is_equal_approx(1.0, 0.01)
	assert_float(entry.get("fill_g") as float).is_equal_approx(0.0, 0.01)
	assert_float(entry.get("fill_b") as float).is_equal_approx(0.0, 0.01)
	assert_float(entry.get("fill_a") as float).is_equal_approx(1.0, 0.01)
	assert_str(entry.get("sub_mode")).is_equal("circle_node")

	env["main"].free()


## C16: CanvasNode deserialization (load).
func test_canvas_node_deserialization() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Inject serialized data directly into the element layer via _load_canvas_node.
	var node_data: Dictionary = {
		"type": "CanvasNode",
		"position_x": 300.0,
		"position_y": 400.0,
		"fill_r": 0.5,
		"fill_g": 0.8,
		"fill_b": 0.2,
		"fill_a": 1.0,
		"sub_mode": "triangle_node",
	}
	main.call("_load_canvas_node", node_data)

	assert_int(el.get_child_count()).is_equal(1)
	var node: Node2D = el.get_child(0) as Node2D
	assert_vector(node.position).is_equal_approx(Vector2(300.0, 400.0), 0.1)
	assert_str(node.get("sub_mode")).is_equal("triangle_node")
	assert_color(node.get("fill_color")).is_equal_approx(Color(0.5, 0.8, 0.2), 0.01)

	# Signals should be connected.
	assert_bool(node.is_connected("clicked", Callable(main, "_on_node_clicked"))).is_true()
	assert_bool(node.is_connected("anchor_changed", Callable(main, "_on_node_anchor_changed").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_moved", Callable(main, "_on_multi_drag_moved").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_ended", Callable(main, "_on_multi_drag_ended").bind(node))).is_true()

	env["main"].free()


# ===== C17-C19: Info Bar ====================================================

## C17: Info bar shows node mode circle hint.
func test_info_bar_node_mode_circle() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var info_bar: Label = env["info_bar"]

	main.call("activate_node_mode", "circle_node")
	var info_text: String = info_bar.text
	assert_str(info_text).contains("Click the canvas to place a circle node")

	env["main"].free()


## C18: Info bar shows node mode triangle hint.
func test_info_bar_node_mode_triangle() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var info_bar: Label = env["info_bar"]

	main.call("activate_node_mode", "triangle_node")
	var info_text: String = info_bar.text
	assert_str(info_text).contains("Click the canvas to place a triangle node")

	env["main"].free()


## C19: Info bar shows node selected hint.
func test_info_bar_node_selected() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var info_bar: Label = env["info_bar"]

	# Place a node so we have something to select.
	main.call("activate_node_mode", "circle_node")
	main.call("place_node", Vector2(100, 100))

	# The node is already selected after placement.
	# Single element selected with get_anchor_points → shows node hint.
	var info_text: String = info_bar.text
	assert_str(info_text).contains("Click color to change")

	env["main"].free()


# ===== C20: Legend Excludes Node Colors =====================================

## C20: Legend excludes node colors.
func test_legend_excludes_node_colors() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Place a shape with BLUE fill.
	var shape: Node2D = _create_label_shape(el, Vector2(0, 0))
	shape.set("fill_color", Color(0.231, 0.51, 0.965))  # Default BLUE

	# Place a node with RED fill.
	var node: Node2D = _create_circle_node(el, Vector2(200, 0))
	node.set("fill_color", Color.RED)

	# Call _refresh_legend.
	main.call("_refresh_legend")

	# Legend panel should have only 1 color (the shape's BLUE).
	var legend_panel: Control = env["legend_panel"]
	# The legend panel stores entry rows in its _entry_rows dictionary.
	# Keys are the Color values currently displayed.
	var entry_rows: Dictionary = legend_panel.get("_entry_rows")
	assert_int(entry_rows.size()).is_equal(1)
	# Only BLUE (shape color) should be present, not RED (node color).
	for color: Color in entry_rows.keys():
		assert_color(color).is_equal_approx(Color(0.231, 0.51, 0.965), 0.01)

	env["main"].free()


# ===== C21: Node Copy/Paste =================================================

## C21: Node copy-paste (if applicable). The codebase doesn't currently have
## copy/paste, so this test checks that the feature doesn't exist or is a no-op.
func test_node_copy_paste() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]

	# Verify there's no copy/paste handler for nodes.
	# The codebase doesn't implement copy/paste for elements.
	# This test verifies that _unhandled_input does not handle Ctrl+C/Ctrl+V.
	assert_bool(main.has_method("_on_copy_requested")).is_false()
	assert_bool(main.has_method("_on_paste_requested")).is_false()

	env["main"].free()


# ===== C22: _on_node_sub_mode_changed Handler ===============================

## C22: _on_node_sub_mode_changed activates node tool.
func test_on_node_sub_mode_changed() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]

	# Ensure node tool is not active.
	main.call("deactivate_node_mode")
	assert_bool(main.get("node_tool_active")).is_false()

	# Emit node_sub_mode_changed via calling the handler directly.
	# (This is connected from Toolbar's signal.)
	main.call("_on_node_sub_mode_changed", "triangle_node")

	assert_bool(main.get("node_tool_active")).is_true()
	assert_str(main.get("node_sub_mode")).is_equal("triangle_node")

	env["main"].free()


# ===== C23: _on_node_clicked Routes Correctly ===============================

## C23: _on_node_clicked routes to _handle_element_clicked.
func test_on_node_clicked_routes_correctly() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]
	var el: Node2D = env["element_layer"]

	# Create a node.
	var node: Node2D = _create_circle_node(el, Vector2(100, 100))

	main.call("activate_select_mode")
	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	main.call("_on_node_clicked", dummy_event, node)

	# Node should be in selected_set.
	var selected_set: Array = main.get("selected_set")
	assert_bool(node in selected_set).is_true()
	assert_object(main.get("primary_selection")).is_same(node)

	env["main"].free()


# ===== C24: Activate Node Tool Deactivates Shape Tool =======================

## C24: Place node while shape tool active auto-switches.
func test_activate_node_tool_deactivates_shape_tool() -> void:
	var env: Dictionary = await _create_main_env()
	var main: Node = env["main"]

	# Activate shape tool.
	main.call("activate_shape_mode", "oval")
	assert_bool(main.get("shape_tool_active")).is_true()

	# Activate node tool.
	main.call("activate_node_mode", "circle_node")

	assert_bool(main.get("shape_tool_active")).is_false()
	assert_bool(main.get("node_tool_active")).is_true()

	env["main"].free()