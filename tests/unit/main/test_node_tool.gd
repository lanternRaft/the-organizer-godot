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

var _main: Node


# ----- Lifecycle -------------------------------------------------------------

func before_test() -> void:
	_main = __scene.instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	_reset_state()


func after_test() -> void:
	_main.free()
	_main = null


# ----- Helpers ---------------------------------------------------------------

func _reset_state() -> void:
	_main.set("node_tool_active", false)
	_main.set("node_sub_mode", "circle_node")
	_main.set("shape_tool_active", false)
	_main.set("select_mode_active", false)
	_main.set("selected_set", [])
	_main.set("primary_selection", null)


func _el() -> Node2D:
	return _main.get_node("%ElementLayer")


func _info_bar() -> Label:
	return _main.get_node("%InfoBar")


func _arrow_manager() -> Node:
	return _main.get_node("ArrowManager")


func _legend_panel() -> Control:
	return _main.get_node("%LegendPanel")


func _create_circle_node(pos: Vector2) -> Node2D:
	var node: Node2D = CANVAS_NODE_SCENE.instantiate()
	node.set("sub_mode", "circle_node")
	node.position = pos
	_el().add_child(node)
	return node


func _create_triangle_node(pos: Vector2) -> Node2D:
	var node: Node2D = CANVAS_NODE_SCENE.instantiate()
	node.set("sub_mode", "triangle_node")
	node.position = pos
	_el().add_child(node)
	return node


func _create_label_shape(pos: Vector2) -> Node2D:
	var shape: Node2D = LABEL_SHAPE_SCENE.instantiate()
	shape.set("rx", 80.0)
	shape.set("ry", 50.0)
	shape.position = pos
	_el().add_child(shape)
	return shape


# ===== C1-C3: Tool Activation ===============================================

## C1: Activate node tool sets correct state.
func test_activate_node_tool() -> void:
	_main.call("activate_node_mode", "circle_node")

	assert_bool(_main.get("node_tool_active")).is_true()
	assert_str(_main.get("node_sub_mode")).is_equal("circle_node")
	assert_bool(_main.get("shape_tool_active")).is_false()
	assert_bool(_main.get("select_mode_active")).is_false()
	assert_int(Input.get_current_cursor_shape()).is_equal(Input.CURSOR_CROSS)


## C2: Node tool deactivates shape tool.
func test_node_tool_deactivates_shape_tool() -> void:
	_main.call("activate_shape_mode", "oval")
	assert_bool(_main.get("shape_tool_active")).is_true()

	_main.call("activate_node_mode", "triangle_node")
	assert_bool(_main.get("node_tool_active")).is_true()
	assert_bool(_main.get("shape_tool_active")).is_false()


## C3: Node tool deactivates select tool.
func test_node_tool_deactivates_select_tool() -> void:
	_main.call("activate_select_mode")
	assert_bool(_main.get("select_mode_active")).is_true()

	_main.call("activate_node_mode", "circle_node")
	assert_bool(_main.get("node_tool_active")).is_true()
	assert_bool(_main.get("select_mode_active")).is_false()


# ===== C4-C5: Place Node ====================================================

## C4: Place circle node.
func test_place_circle_node() -> void:
	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(150, 250))

	var children: Array[Node] = _el().get_children()
	assert_int(children.size()).is_equal(1)
	var node: Node2D = children[0] as Node2D
	assert_bool(node != null).is_true()
	assert_vector(node.position).is_equal(Vector2(150, 250))
	assert_str(node.get("sub_mode")).is_equal("circle_node")

	assert_bool(_main.get("node_tool_active")).is_false()
	assert_bool(_main.get("select_mode_active")).is_true()

	var selected_set: Array = _main.get("selected_set")
	assert_bool(node in selected_set).is_true()
	assert_object(_main.get("primary_selection")).is_same(node)
	assert_object(_main.get("last_placed")).is_same(node)

	assert_bool(node.is_connected("clicked", Callable(_main, "_on_node_clicked"))).is_true()
	assert_bool(node.is_connected("anchor_changed", Callable(_main, "_on_node_anchor_changed").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_moved", Callable(_main, "_on_multi_drag_moved").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_ended", Callable(_main, "_on_multi_drag_ended").bind(node))).is_true()

	var save_path: String = _main.get("SAVE_PATH")
	assert_bool(FileAccess.file_exists(save_path)).is_true()


## C5: Place triangle node.
func test_place_triangle_node() -> void:
	_main.call("activate_node_mode", "triangle_node")
	_main.call("place_node", Vector2(300, 100))

	var children: Array[Node] = _el().get_children()
	assert_int(children.size()).is_equal(1)
	var node: Node2D = children[0] as Node2D
	assert_str(node.get("sub_mode")).is_equal("triangle_node")
	assert_vector(node.position).is_equal(Vector2(300, 100))
	assert_bool(_main.get("node_tool_active")).is_false()
	assert_bool(_main.get("select_mode_active")).is_true()


# ===== C6: Empty Canvas Click Routes to place_node ==========================

## C6: Empty canvas click in node mode routes to place_node.
func test_empty_canvas_click_in_node_mode() -> void:
	_main.call("activate_node_mode", "circle_node")
	assert_int(_el().get_child_count()).is_equal(0)

	_main.call("_on_empty_canvas_clicked", Vector2(200, 200))

	assert_int(_el().get_child_count()).is_equal(1)
	var node: Node2D = _el().get_child(0) as Node2D
	assert_vector(node.position).is_equal(Vector2(200, 200))


# ===== C7: Escape Exits Node Mode ===========================================

## C7: Escape key exits node mode without placing.
func test_escape_exits_node_mode() -> void:
	_main.call("activate_node_mode", "circle_node")
	assert_bool(_main.get("node_tool_active")).is_true()

	var escape_event: InputEventKey = InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	_main.call("_unhandled_input", escape_event)

	assert_bool(_main.get("node_tool_active")).is_false()
	assert_int(_el().get_child_count()).is_equal(0)
	assert_int(Input.get_current_cursor_shape()).is_equal(Input.CURSOR_ARROW)


# ===== C8-C10: Node Click Selection =========================================

## C8: Node click selects.
func test_node_click_selects() -> void:
	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(100, 100))
	_main.call("clear_selection")
	_main.call("activate_select_mode")
	var selected_set: Array = _main.get("selected_set")
	assert_int(selected_set.size()).is_equal(0)

	var node: Node2D = _el().get_child(0)
	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	_main.call("_on_node_clicked", dummy_event, node)

	assert_bool(node in selected_set).is_true()
	assert_object(_main.get("primary_selection")).is_same(node)


## C9: Shift-click adds to multi-select.
func test_node_shift_click_multiselect() -> void:
	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(100, 100))
	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(200, 100))

	var node1: Node2D = _el().get_child(0)
	var node2: Node2D = _el().get_child(1)

	_main.call("clear_selection")
	_main.call("activate_select_mode")

	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	_main.call("_on_node_clicked", dummy_event, node1)
	var selected_set: Array = _main.get("selected_set")
	assert_int(selected_set.size()).is_equal(1)

	var shift_press: InputEventKey = InputEventKey.new()
	shift_press.keycode = KEY_SHIFT
	shift_press.pressed = true
	Input.parse_input_event(shift_press)

	_main.call("_on_node_clicked", dummy_event, node2)

	selected_set = _main.get("selected_set")
	assert_int(selected_set.size()).is_equal(2)
	assert_bool(node1 in selected_set).is_true()
	assert_bool(node2 in selected_set).is_true()
	assert_str(_info_bar().text).contains("2 selected")

	var shift_release: InputEventKey = InputEventKey.new()
	shift_release.keycode = KEY_SHIFT
	shift_release.pressed = false
	Input.parse_input_event(shift_release)


## C10: Node click clears shape selection.
func test_node_click_clears_shape_selection() -> void:
	var shape: Node2D = _create_label_shape(Vector2(0, 0))
	shape.connect("clicked", Callable(_main, "_on_shape_clicked"))
	_main.call("activate_select_mode")
	_main.call("select_element", shape, false)
	var selected_set: Array = _main.get("selected_set")
	assert_bool(shape in selected_set).is_true()

	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(100, 100))
	_main.call("clear_selection")
	_main.call("activate_select_mode")
	_main.call("select_element", shape, false)
	selected_set = _main.get("selected_set")
	assert_bool(shape in selected_set).is_true()

	var node: Node2D = _el().get_child(1)
	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	_main.call("_on_node_clicked", dummy_event, node)

	selected_set = _main.get("selected_set")
	assert_bool(shape in selected_set).is_false()
	assert_bool(node in selected_set).is_true()
	assert_int(selected_set.size()).is_equal(1)


# ===== C11: Node Color Change ===============================================

## C11: Node color change via selection menu.
func test_node_color_change() -> void:
	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(100, 100))
	_main.call("_on_menu_color_selected", Color.RED)

	var node: Node2D = _el().get_child(0)
	assert_bool(node.get("fill_color")).is_equal(Color.RED)
	var save_path_c11: String = _main.get("SAVE_PATH")
	assert_bool(FileAccess.file_exists(save_path_c11)).is_true()


# ===== C12-C13: Delete Node =================================================

## C12: Delete node.
func test_delete_node() -> void:
	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(100, 100))

	var delete_event: InputEventKey = InputEventKey.new()
	delete_event.keycode = KEY_DELETE
	delete_event.pressed = true
	_main.call("_unhandled_input", delete_event)

	assert_int(_el().get_child_count()).is_equal(0)
	var selected_set: Array = _main.get("selected_set")
	assert_int(selected_set.size()).is_equal(0)
	assert_object(_main.get("primary_selection")).is_null()
	var save_path: String = _main.get("SAVE_PATH")
	assert_bool(FileAccess.file_exists(save_path)).is_true()


## C13: Delete node with connected arrows.
func test_delete_node_with_arrows() -> void:
	var mgr: Node = _arrow_manager()

	_main.call("activate_shape_mode", "oval")
	_main.call("place_shape", Vector2(0, 0))
	var shape: Node2D = _el().get_child(0)

	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(200, 0))
	var node: Node2D = _el().get_child(1)

	mgr.call("_refresh_shape_list")
	mgr.call("_create_arrow", shape, "right", node, "left")
	var arrows: Array = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(1)

	_main.call("clear_selection")
	_main.call("activate_select_mode")
	_main.call("select_element", node, false)

	var delete_event: InputEventKey = InputEventKey.new()
	delete_event.keycode = KEY_DELETE
	delete_event.pressed = true
	_main.call("_unhandled_input", delete_event)

	assert_int(_el().get_child_count()).is_equal(1)
	arrows = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(0)


# ===== C14: Select All Includes Nodes =======================================

## C14: Select all includes nodes.
func test_select_all_includes_nodes() -> void:
	var shape1: Node2D = _create_label_shape(Vector2(0, 0))
	var shape2: Node2D = _create_label_shape(Vector2(100, 0))
	var node: Node2D = _create_circle_node(Vector2(200, 0))

	_main.call("activate_select_mode")

	var ctrl_a: InputEventKey = InputEventKey.new()
	ctrl_a.keycode = KEY_A
	ctrl_a.ctrl_pressed = true
	ctrl_a.pressed = true
	_main.call("_unhandled_input", ctrl_a)

	var selected_set: Array = _main.get("selected_set")
	assert_int(selected_set.size()).is_equal(3)
	assert_bool(shape1 in selected_set).is_true()
	assert_bool(shape2 in selected_set).is_true()
	assert_bool(node in selected_set).is_true()


# ===== C15-C16: Serialization ===============================================

## C15: CanvasNode serialization.
func test_canvas_node_serialization() -> void:
	var node: Node2D = _create_circle_node(Vector2(100, 200))
	node.set("fill_color", Color(1.0, 0.0, 0.0, 1.0))

	var data: Dictionary = _main.call("serialize_canvas")
	var elements: Array = data.get("elements", [])
	assert_int(elements.size()).is_equal(1)

	var entry: Dictionary = elements[0]
	assert_str(entry.get("type")).is_equal("CanvasNode")
	assert_float(entry.get("position_x")).is_equal_approx(100.0, 0.1)
	assert_float(entry.get("position_y")).is_equal_approx(200.0, 0.1)
	assert_float(entry.get("fill_r")).is_equal_approx(1.0, 0.01)
	assert_float(entry.get("fill_g")).is_equal_approx(0.0, 0.01)
	assert_float(entry.get("fill_b")).is_equal_approx(0.0, 0.01)
	assert_float(entry.get("fill_a")).is_equal_approx(1.0, 0.01)
	assert_str(entry.get("sub_mode")).is_equal("circle_node")


## C16: CanvasNode deserialization (load).
func test_canvas_node_deserialization() -> void:
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
	_main.call("_load_canvas_node", node_data)

	assert_int(_el().get_child_count()).is_equal(1)
	var node: Node2D = _el().get_child(0) as Node2D
	assert_vector(node.position).is_equal_approx(Vector2(300.0, 400.0), 0.1)
	assert_str(node.get("sub_mode")).is_equal("triangle_node")
	var _fill: Color = node.get("fill_color")
	assert_float(_fill.r).is_equal_approx(0.5, 0.01)
	assert_float(_fill.g).is_equal_approx(0.8, 0.01)
	assert_float(_fill.b).is_equal_approx(0.2, 0.01)
	assert_float(_fill.a).is_equal_approx(1.0, 0.01)

	assert_bool(node.is_connected("clicked", Callable(_main, "_on_node_clicked"))).is_true()
	assert_bool(node.is_connected("anchor_changed", Callable(_main, "_on_node_anchor_changed").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_moved", Callable(_main, "_on_multi_drag_moved").bind(node))).is_true()
	assert_bool(node.is_connected("multi_drag_ended", Callable(_main, "_on_multi_drag_ended").bind(node))).is_true()


# ===== C17-C19: Info Bar ====================================================

## C17: Info bar shows node mode circle hint.
func test_info_bar_node_mode_circle() -> void:
	_main.call("activate_node_mode", "circle_node")
	assert_str(_info_bar().text).contains("Click the canvas to place a circle node")


## C18: Info bar shows node mode triangle hint.
func test_info_bar_node_mode_triangle() -> void:
	_main.call("activate_node_mode", "triangle_node")
	assert_str(_info_bar().text).contains("Click the canvas to place a triangle node")


## C19: Info bar shows node selected hint.
func test_info_bar_node_selected() -> void:
	_main.call("activate_node_mode", "circle_node")
	_main.call("place_node", Vector2(100, 100))
	assert_str(_info_bar().text).contains("Click color to change")


# ===== C20: Legend Excludes Node Colors =====================================

## C20: Legend excludes node colors.
func test_legend_excludes_node_colors() -> void:
	var shape: Node2D = _create_label_shape(Vector2(0, 0))
	shape.set("fill_color", Color(0.231, 0.51, 0.965))

	var node: Node2D = _create_circle_node(Vector2(200, 0))
	node.set("fill_color", Color.RED)

	_main.call("_refresh_legend")

	var entry_rows: Dictionary = _legend_panel().get("_entry_rows")
	assert_int(entry_rows.size()).is_equal(1)
	for color: Color in entry_rows.keys():
		assert_float(color.r).is_equal_approx(0.231, 0.01)
		assert_float(color.g).is_equal_approx(0.51, 0.01)
		assert_float(color.b).is_equal_approx(0.965, 0.01)
		assert_float(color.a).is_equal_approx(1.0, 0.01)


# ===== C21: Node Copy/Paste =================================================

## C21: Copy/paste is not implemented — verify absence of handlers.
func test_node_copy_paste() -> void:
	assert_bool(_main.has_method("_on_copy_requested")).is_false()
	assert_bool(_main.has_method("_on_paste_requested")).is_false()


# ===== C22: _on_node_sub_mode_changed Handler ===============================

## C22: _on_node_sub_mode_changed activates node tool.
func test_on_node_sub_mode_changed() -> void:
	_main.call("deactivate_node_mode")
	assert_bool(_main.get("node_tool_active")).is_false()

	_main.call("_on_node_sub_mode_changed", "triangle_node")

	assert_bool(_main.get("node_tool_active")).is_true()
	assert_str(_main.get("node_sub_mode")).is_equal("triangle_node")


# ===== C23: _on_node_clicked Routes Correctly ===============================

## C23: _on_node_clicked routes to _handle_element_clicked.
func test_on_node_clicked_routes_correctly() -> void:
	var node: Node2D = _create_circle_node(Vector2(100, 100))

	_main.call("activate_select_mode")
	var dummy_event: InputEventMouseButton = InputEventMouseButton.new()
	_main.call("_on_node_clicked", dummy_event, node)

	var selected_set: Array = _main.get("selected_set")
	assert_bool(node in selected_set).is_true()
	assert_object(_main.get("primary_selection")).is_same(node)


# ===== C24: Activate Node Tool Deactivates Shape Tool =======================

## C24: Place node while shape tool active auto-switches.
func test_activate_node_tool_deactivates_shape_tool() -> void:
	_main.call("activate_shape_mode", "oval")
	assert_bool(_main.get("shape_tool_active")).is_true()

	_main.call("activate_node_mode", "circle_node")

	assert_bool(_main.get("shape_tool_active")).is_false()
	assert_bool(_main.get("node_tool_active")).is_true()
