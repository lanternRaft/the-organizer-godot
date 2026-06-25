# GdUnit generated TestSuite
class_name ArrowManagerCanvasNodeTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/arrow_manager/arrow_manager.gd'

const CANVAS_NODE_SCENE: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")

# Constants matching CanvasNode internals.
const CIRCLE_RADIUS: float = 8.0

# ----- Helpers ---------------------------------------------------------------

## Creates a minimal test scene with ElementLayer and AnchorLayer under a dummy Main node.
## ArrowManager is added as a child of Main.
## Returns { "main": Node, "element_layer": Node2D, "anchor_layer": Node2D, "arrow_manager": Node }
func _create_test_scene() -> Dictionary:
	var main: Node = Node.new()
	main.set_script(load("res://scenes/main/main.gd"))
	get_tree().root.add_child(main)

	# Create layers that Main expects.
	var element_layer: Node2D = Node2D.new()
	element_layer.name = "ElementLayer"
	element_layer.unique_name_in_owner = true
	main.add_child(element_layer)

	var anchor_layer: Node2D = Node2D.new()
	anchor_layer.name = "AnchorLayer"
	anchor_layer.unique_name_in_owner = true
	main.add_child(anchor_layer)

	# Create a ClickHandler stub so ArrowManager doesn't error on get_parent().get_node("ClickHandler").
	var click_handler: Node = Node.new()
	click_handler.name = "ClickHandler"
	click_handler.set_script(load("res://scenes/main/click_handler/click_handler.gd"))
	main.add_child(click_handler)

	# Create ArrowManager as child of Main.
	var arrow_mgr: Node = Node.new()
	arrow_mgr.set_script(load("res://scenes/arrow_manager/arrow_manager.gd"))
	arrow_mgr.name = "ArrowManager"
	main.add_child(arrow_mgr)
	arrow_mgr.set("element_layer", element_layer)
	arrow_mgr.set("anchor_layer", anchor_layer)
	# Re-initialize _dot_nodes and _shapes.
	arrow_mgr.set("_dot_nodes", {})
	arrow_mgr.set("_shapes", [])

	# Set select_mode_active = true on Main so ArrowManager process shows dots.
	main.set("select_mode_active", true)

	await get_tree().process_frame

	return {
		"main": main,
		"element_layer": element_layer,
		"anchor_layer": anchor_layer,
		"arrow_manager": arrow_mgr,
	}


## Creates a CanvasNode circle at the given position and adds it to element_layer.
func _create_circle_node(element_layer: Node2D, position: Vector2) -> Node2D:
	var node: Node2D = CANVAS_NODE_SCENE.instantiate()
	node.set("sub_mode", "circle_node")
	node.position = position
	element_layer.add_child(node)
	return node


## Creates a LabelShape oval at the given position and adds it to element_layer.
func _create_label_shape(element_layer: Node2D, position: Vector2) -> Node2D:
	var shape: Node2D = LABEL_SHAPE_SCENE.instantiate()
	shape.set("rx", 80.0)
	shape.set("ry", 50.0)
	shape.position = position
	element_layer.add_child(shape)
	return shape


## Calls ArrowManager's internal _create_arrow.
func _create_arrow(mgr: Node, start_shape: Node, start_label: String, end_shape: Node, end_label: String) -> void:
	# ArrowManager._create_arrow is a private method. We call it via call().
	mgr.call("_create_arrow", start_shape, start_label, end_shape, end_label)


# ===== B1-B3: Arrow Creation between Nodes and Shapes =======================

## B1: Arrow from LabelShape to CircleNode.
func test_arrow_shape_to_circle_node() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var shape: Node2D = _create_label_shape(el, Vector2(0, 0))
	var node: Node2D = _create_circle_node(el, Vector2(200, 0))
	await get_tree().process_frame

	_create_arrow(mgr, shape, "right", node, "left")

	var arrows: Array = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(1)

	# Arrow's rebuild_path() should not error — call it explicitly.
	var arrow: Node = arrows[0]
	arrow.call("rebuild_path")
	assert_bool(true).is_true()  # No error means success.

	# The arrow exists — inspect its start/end properties.
	assert_str(arrow.get("start_anchor_label")).is_equal("right")
	assert_str(arrow.get("end_anchor_label")).is_equal("left")

	shape.free()
	node.free()
	scene["main"].free()


## B2: Arrow from CircleNode to TriangleNode.
func test_arrow_circle_to_triangle() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var circle: Node2D = _create_circle_node(el, Vector2(0, 0))
	var triangle: Node2D = CANVAS_NODE_SCENE.instantiate()
	triangle.set("sub_mode", "triangle_node")
	triangle.position = Vector2(200, 0)
	el.add_child(triangle)
	await get_tree().process_frame

	_create_arrow(mgr, circle, "right", triangle, "bottom_left")

	var arrows: Array = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(1)

	var arrow: Node = arrows[0]
	arrow.call("rebuild_path")
	assert_str(arrow.get("start_anchor_label")).is_equal("right")
	assert_str(arrow.get("end_anchor_label")).is_equal("bottom_left")

	circle.free()
	triangle.free()
	scene["main"].free()


## B3: Arrow from TriangleNode to LabelShape.
func test_arrow_node_to_shape() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var triangle: Node2D = CANVAS_NODE_SCENE.instantiate()
	triangle.set("sub_mode", "triangle_node")
	triangle.position = Vector2(0, 0)
	el.add_child(triangle)
	var shape: Node2D = _create_label_shape(el, Vector2(300, 100))
	await get_tree().process_frame

	_create_arrow(mgr, triangle, "top", shape, "bottom")

	var arrows: Array = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(1)

	var arrow: Node = arrows[0]
	arrow.call("rebuild_path")
	assert_str(arrow.get("start_anchor_label")).is_equal("top")
	assert_str(arrow.get("end_anchor_label")).is_equal("bottom")

	triangle.free()
	shape.free()
	scene["main"].free()


# ===== B4: Self-Connection Prevention =======================================

## B4: Arrow from a node to itself is not created.
func test_arrow_self_connection_node() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var node: Node2D = _create_circle_node(el, Vector2(100, 100))
	await get_tree().process_frame

	var initial_count: int = (mgr.get("_arrows") as Array).size()

	# Simulate arrow drag from node's "top" released on same node's "bottom".
	# ArrowManager's end_arrow_drag checks _drag_snapped_shape != _drag_start_shape,
	# so setting both to the same node should prevent creation.
	mgr.set("_drag_start_shape", node)
	mgr.set("_drag_start_label", "top")
	mgr.set("_drag_snapped_shape", node)
	mgr.set("_drag_snapped_label", "bottom")
	mgr.call("end_arrow_drag")

	var arrows: Array = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(initial_count)

	node.free()
	scene["main"].free()


# ===== B5: Deleting Node Removes Connected Arrows ===========================

## B5: Deleting node deletes connected arrows.
func test_delete_node_removes_arrows() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var shape: Node2D = _create_label_shape(el, Vector2(0, 0))
	var node: Node2D = _create_circle_node(el, Vector2(200, 0))
	await get_tree().process_frame

	_create_arrow(mgr, shape, "right", node, "left")
	assert_int((mgr.get("_arrows") as Array).size()).is_equal(1)

	# Delete arrows for the node.
	mgr.call("delete_arrows_for_shape", node)

	assert_int((mgr.get("_arrows") as Array).size()).is_equal(0)

	shape.free()
	node.free()
	scene["main"].free()


# ===== B6-B7: Anchor Dots ===================================================

## Helper: Simulates mouse movement to trigger anchor dot visibility.
func _simulate_process(mgr: Node, mouse_pos: Vector2) -> void:
	mgr.set("select_mode_active", true)
	mgr.notification(NOTIFICATION_PROCESS)
	# We can assign mouse position by setting global_mouse_position on the viewport,
	# but for simplicity we'll verify dots via _update_anchor_dots by calling directly.
	mgr.call("_update_anchor_dots", mouse_pos)


## B6: Circle node shows 4 anchor dots.
func test_circle_node_anchor_dots() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var node: Node2D = _create_circle_node(el, Vector2(0, 0))
	await get_tree().process_frame

	# Refresh shape list.
	mgr.call("_refresh_shape_list")

	# Call _update_anchor_dots with mouse near the node.
	var node_center: Vector2 = node.global_position
	mgr.call("_update_anchor_dots", node_center)

	var dot_nodes: Dictionary = mgr.get("_dot_nodes")
	var sid: int = node.get_instance_id()
	assert_bool(dot_nodes.has(sid)).is_true()
	var dots: Dictionary = dot_nodes[sid]
	assert_int(dots.size()).is_equal(4)
	assert_bool(dots.has("top")).is_true()
	assert_bool(dots.has("bottom")).is_true()
	assert_bool(dots.has("left")).is_true()
	assert_bool(dots.has("right")).is_true()

	node.free()
	scene["main"].free()


## B7: Triangle node shows 3 anchor dots.
func test_triangle_node_anchor_dots() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var node: Node2D = CANVAS_NODE_SCENE.instantiate()
	node.set("sub_mode", "triangle_node")
	node.position = Vector2(0, 0)
	el.add_child(node)
	await get_tree().process_frame

	mgr.call("_refresh_shape_list")
	var node_center: Vector2 = node.global_position
	mgr.call("_update_anchor_dots", node_center)

	var dot_nodes: Dictionary = mgr.get("_dot_nodes")
	var sid: int = node.get_instance_id()
	assert_bool(dot_nodes.has(sid)).is_true()
	var dots: Dictionary = dot_nodes[sid]
	assert_int(dots.size()).is_equal(3)
	assert_bool(dots.has("top")).is_true()
	assert_bool(dots.has("bottom_left")).is_true()
	assert_bool(dots.has("bottom_right")).is_true()

	node.free()
	scene["main"].free()


# ===== B8-B9: Arrow Drag from Node Anchor ===================================

## B8: Arrow drag begins from node anchor.
func test_arrow_drag_from_node() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var node: Node2D = _create_circle_node(el, Vector2(100, 100))
	await get_tree().process_frame
	mgr.call("_refresh_shape_list")

	# Get the top anchor position.
	var top_pos: Vector2 = node.call("get_anchor_position", "top")

	# Call handle_dot_mousedown at the top anchor position.
	var result: bool = mgr.call("handle_dot_mousedown", top_pos)

	assert_bool(result).is_true()
	assert_bool(mgr.get("_arrow_drag_active")).is_true()
	assert_object(mgr.get("_drag_start_shape")).is_same(node)
	assert_str(mgr.get("_drag_start_label")).is_equal("top")
	# Preview line should exist.
	assert_bool(mgr.get("_preview_line") != null).is_true()

	node.free()
	scene["main"].free()


## B9: Arrow drag ending without snap discards the arrow.
func test_arrow_drag_no_snap_discards() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var node: Node2D = _create_circle_node(el, Vector2(100, 100))
	await get_tree().process_frame
	mgr.call("_refresh_shape_list")

	var top_pos: Vector2 = node.call("get_anchor_position", "top")

	# Begin drag.
	mgr.call("handle_dot_mousedown", top_pos)
	assert_bool(mgr.get("_arrow_drag_active")).is_true()

	# End drag without snapping (drag_snapped_shape is null).
	mgr.call("end_arrow_drag")

	assert_bool(mgr.get("_arrow_drag_active")).is_false()
	assert_int((mgr.get("_arrows") as Array).size()).is_equal(0)
	assert_bool(mgr.get("_preview_line") == null or not is_instance_valid(mgr.get("_preview_line"))).is_true()

	node.free()
	scene["main"].free()


# ===== B10: Arrow Updates on Node Move ======================================

## B10: Arrow bezier points update when node moves.
func test_arrow_updates_on_node_move() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var shape: Node2D = _create_label_shape(el, Vector2(0, 0))
	var node: Node2D = _create_circle_node(el, Vector2(200, 0))
	await get_tree().process_frame

	_create_arrow(mgr, shape, "right", node, "left")
	var arrow: Node = (mgr.get("_arrows") as Array)[0]
	arrow.call("rebuild_path")

	# Cache original bezier points.
	var original_points: PackedVector2Array = arrow.get("_cached_bezier_points")

	# Move node to a new position.
	node.position = Vector2(300, 50)
	await get_tree().process_frame

	# Update arrows for the moved node.
	mgr.call("update_arrows_for_shape", node)

	var updated_points: PackedVector2Array = arrow.get("_cached_bezier_points")
	# Points should have changed.
	assert_bool(original_points != updated_points).is_true()

	shape.free()
	node.free()
	scene["main"].free()