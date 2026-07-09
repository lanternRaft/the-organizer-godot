# GdUnit generated TestSuite
class_name ArrowManagerAnchorsTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")

# TestSuite generated from
const __source: String = "res://scenes/arrow_manager/arrow_manager.gd"

const CANVAS_NODE_SCENE: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")

# Constants matching CanvasNode internals.
const CIRCLE_RADIUS: float = 8.0

# ----- Helpers ---------------------------------------------------------------

## Minimal script for the test's main node — provides only the properties
## that ArrowManager and the test assertions rely on, without pulling in
## Main.gd's complex scene structure requirements.
const _MAIN_STUB_SCRIPT: GDScript = preload("res://tests/unit/arrow_manager/main_stub.gd")


## Creates a minimal test scene with ElementLayer and AnchorLayer under a dummy Main node.
## ArrowManager is added as a child of Main.
## Returns { "main": Node, "element_layer": Node2D, "anchor_layer": Node2D, "arrow_manager": Node }
func _create_test_scene() -> Dictionary:
	var main: Node = Node.new()
	main.set_script(_MAIN_STUB_SCRIPT)

	# Build the tree structure expected by ArrowManager @onready vars.
	var canvas: Node2D = Node2D.new()
	canvas.name = "Canvas"
	main.add_child(canvas)
	canvas.owner = main

	var element_layer: Node2D = Node2D.new()
	element_layer.name = "ElementLayer"
	element_layer.unique_name_in_owner = true
	canvas.add_child(element_layer)
	element_layer.owner = main

	var anchor_layer: Node2D = Node2D.new()
	anchor_layer.name = "AnchorLayer"
	anchor_layer.unique_name_in_owner = true
	canvas.add_child(anchor_layer)
	anchor_layer.owner = main

	# Create a ClickHandler stub so ArrowManager doesn't error on get_parent().get_node("ClickHandler").
	var click_handler: Node = Node.new()
	click_handler.name = "ClickHandler"
	click_handler.set_script(load("res://scenes/main/click_handler/click_handler.gd"))
	main.add_child(click_handler)
	click_handler.owner = main

	# Create ArrowManager as child of Main.
	var arrow_mgr: Node = Node.new()
	arrow_mgr.set_script(load("res://scenes/arrow_manager/arrow_manager.gd"))
	arrow_mgr.name = "ArrowManager"
	main.add_child(arrow_mgr)
	arrow_mgr.owner = main

	# Add the full tree to the scene (triggers @onready and _ready on all children).
	get_tree().root.add_child(main)

	# Re-initialize _dot_nodes and _elements (clears any state set during _ready).
	arrow_mgr.set("_dot_nodes", {})
	arrow_mgr.set("_elements", [])

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
func _create_circle_node(element_layer: Node2D, position: Vector2) -> CanvasNode:
	var node: CanvasNode = CANVAS_NODE_SCENE.instantiate()
	node.sub_mode = "circle_node"
	node.position = position
	element_layer.add_child(node)
	return node


## Creates a CanvasNode triangle at the given position and adds it to element_layer.
func _create_triangle_node(element_layer: Node2D, position: Vector2) -> CanvasNode:
	var node: CanvasNode = CANVAS_NODE_SCENE.instantiate()
	node.sub_mode = "triangle_node"
	node.position = position
	element_layer.add_child(node)
	return node


## Creates a LabelShape oval at the given position and adds it to element_layer.
func _create_label_shape(element_layer: Node2D, position: Vector2) -> LabelShape:
	var shape: LabelShape = LABEL_SHAPE_SCENE.instantiate()
	shape.rx = 80.0
	shape.ry = 50.0
	shape.position = position
	element_layer.add_child(shape)
	return shape


# ===== Test: ArrowManager reads anchor positions via get_anchor_positions ====


## Verifies that ArrowManager's internal anchor-reading helpers use
## get_anchor_positions() from CanvasElement to determine positions.
func test_arrow_manager_reads_anchor_positions() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	# Create a LabelShape (subclass of CanvasElement) at the origin.
	var shape: LabelShape = _create_label_shape(el, Vector2(0, 0))
	await get_tree().process_frame

	# Force refresh the element list.
	mgr.call("_refresh_element_list")

	# Get anchor labels via _get_anchor_labels_from_element (uses get_anchor_positions()).
	var labels: Array = mgr.call("_get_anchor_labels_from_element", shape)
	assert_int(labels.size()).is_equal(4)
	assert_bool("top" in labels).is_true()
	assert_bool("bottom" in labels).is_true()
	assert_bool("left" in labels).is_true()
	assert_bool("right" in labels).is_true()

	# Verify edge global position for "right" anchor.
	var right_edge: Vector2 = mgr.call("_get_anchor_edge_global_position", shape, "right")
	var expected_right: Vector2 = shape.to_global(Vector2(80.0, 0.0))
	assert_vector(right_edge).is_equal(expected_right)

	# Verify dot global position for "top" anchor (pushed outward by 5px).
	var top_dot: Vector2 = mgr.call("_get_anchor_dot_global_position", shape, "top")
	var expected_top: Vector2 = shape.to_global(Vector2(0.0, -50.0 - 5.0))
	assert_vector(top_dot).is_equal(expected_top)

	shape.queue_free()
	var main: Node = scene["main"]
	main.queue_free()
	await get_tree().process_frame


# ===== Test: ArrowManager handles LabelShape anchors correctly ===============


## Verifies that ArrowManager works with LabelShape anchors end-to-end:
## creating an arrow between two LabelShapes and updating arrows after move.
func test_arrow_manager_label_shape_anchors() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var shape_a: LabelShape = _create_label_shape(el, Vector2(0, 0))
	var shape_b: LabelShape = _create_label_shape(el, Vector2(200, 0))
	await get_tree().process_frame

	# Create an arrow from shape_a's "right" to shape_b's "left".
	mgr.call("_create_arrow", shape_a, "right", shape_b, "left")

	var arrows: Array[Arrow] = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(1)

	var arrow: Arrow = arrows[0]
	arrow.rebuild_path()
	assert_str(arrow.start_anchor_label).is_equal("right")
	assert_str(arrow.end_anchor_label).is_equal("left")

	# Move shape_a and update arrows.
	shape_a.position = Vector2(50, 0)
	mgr.call("update_arrows_for_element", shape_a)

	var updated_points: PackedVector2Array = arrow._cached_bezier_points
	assert_bool(updated_points.size() > 0).is_true()

	# The first point (start) should have changed since shape_a moved.
	# Original position was (0, 0), now it's (50, 0), so the right anchor
	# is now at (130, 0) instead of (80, 0).
	var expected_start: Vector2 = Vector2(130.0, 0.0)
	assert_vector(updated_points[0]).is_equal(expected_start)

	shape_a.queue_free()
	shape_b.queue_free()
	await get_tree().process_frame
	var main: Node = scene["main"]
	main.queue_free()
	await get_tree().process_frame


# ===== Test: ArrowManager handles CanvasNode circle anchors correctly ========


## Verifies that ArrowManager correctly reads circle node anchors
## (4 cardinal points) and creates/updates arrows correctly.
func test_arrow_manager_canvas_node_circle_anchors() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var node: CanvasNode = _create_circle_node(el, Vector2(0, 0))
	await get_tree().process_frame

	mgr.call("_refresh_element_list")

	# Verify 4 anchor labels are read via get_anchor_positions().
	var labels: Array = mgr.call("_get_anchor_labels_from_element", node)
	assert_int(labels.size()).is_equal(4)
	assert_bool("top" in labels).is_true()
	assert_bool("bottom" in labels).is_true()
	assert_bool("left" in labels).is_true()
	assert_bool("right" in labels).is_true()

	# Verify the "right" anchor edge position.
	var right_edge: Vector2 = mgr.call("_get_anchor_edge_global_position", node, "right")
	var expected: Vector2 = node.to_global(Vector2(8.0, 0.0))
	assert_vector(right_edge).is_equal(expected)

	# Verify the "top" anchor dot position (pushed outward).
	var top_dot: Vector2 = mgr.call("_get_anchor_dot_global_position", node, "top")
	var expected_top: Vector2 = node.to_global(Vector2(0.0, -8.0 - 5.0))
	assert_vector(top_dot).is_equal(expected_top)

	# Create an arrow from this node to a LabelShape.
	var shape: LabelShape = _create_label_shape(el, Vector2(200, 0))
	await get_tree().process_frame

	mgr.call("_create_arrow", node, "right", shape, "left")
	var arrows: Array[Arrow] = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(1)

	var arrow: Arrow = arrows[0]
	arrow.rebuild_path()
	# Arrow path should start at node's right edge and end at shape's left edge.
	var pts: PackedVector2Array = arrow._cached_bezier_points
	assert_bool(pts.size() > 0).is_true()
	# Start should be node's right edge: (0,0) + (8,0) = (8,0).
	# End should be shape's left edge: (200,0) + (-80,0) = (120,0).
	assert_vector(pts[0]).is_equal(Vector2(8.0, 0.0))
	assert_vector(pts[pts.size() - 1]).is_equal(Vector2(120.0, 0.0))

	# Move the node and update arrows.
	node.position = Vector2(50, 0)
	mgr.call("update_arrows_for_element", node)

	var updated_pts: Variant = arrow.get("_cached_bezier_points")
	# Start should now be (58, 0).
	assert_vector(updated_pts[0]).is_equal(Vector2(58.0, 0.0))

	node.queue_free()
	shape.queue_free()
	await get_tree().process_frame
	var main: Node = scene["main"]
	main.queue_free()
	await get_tree().process_frame


# ===== Test: ArrowManager handles CanvasNode triangle anchors correctly ======


## Verifies that ArrowManager correctly reads triangle node anchors
## (3 vertex points) and creates/updates arrows correctly.
func test_arrow_manager_canvas_node_triangle_anchors() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var mgr: Node = scene["arrow_manager"]

	var node: CanvasNode = _create_triangle_node(el, Vector2(0, 0))
	await get_tree().process_frame

	mgr.call("_refresh_element_list")

	# Verify 3 anchor labels are read via get_anchor_positions().
	var labels: Array = mgr.call("_get_anchor_labels_from_element", node)
	assert_int(labels.size()).is_equal(3)
	assert_bool("top" in labels).is_true()
	assert_bool("bottom_left" in labels).is_true()
	assert_bool("bottom_right" in labels).is_true()

	# Verify the "top" anchor edge position.
	var top_edge: Vector2 = mgr.call("_get_anchor_edge_global_position", node, "top")
	var expected_top: Vector2 = node.to_global(Vector2(0.0, -8.0))
	assert_vector(top_edge).is_equal(expected_top)

	# Verify the "bottom_left" anchor dot position (pushed outward).
	var bl_dot: Vector2 = mgr.call("_get_anchor_dot_global_position", node, "bottom_left")
	var bl_offset: Vector2 = Vector2(-7.0, 4.0)
	var bl_outward: Vector2 = bl_offset.normalized()
	var expected_bl: Vector2 = node.to_global(bl_offset + bl_outward * 5.0)
	assert_vector(bl_dot).is_equal(expected_bl)

	# Create an arrow from this triangle node to a LabelShape.
	var shape: LabelShape = _create_label_shape(el, Vector2(200, 0))
	await get_tree().process_frame

	mgr.call("_create_arrow", node, "bottom_right", shape, "left")
	var arrows: Array[Arrow] = mgr.get("_arrows")
	assert_int(arrows.size()).is_equal(1)

	var arrow: Arrow = arrows[0]
	arrow.rebuild_path()
	var pts: PackedVector2Array = arrow._cached_bezier_points
	assert_bool(pts.size() > 0).is_true()
	# Start should be triangle's bottom_right edge: (7, 4).
	assert_vector(pts[0]).is_equal(Vector2(7.0, 4.0))
	# End should be shape's left edge: (200,0) + (-80,0) = (120, 0).
	assert_vector(pts[pts.size() - 1]).is_equal(Vector2(120.0, 0.0))

	# Move the node and update arrows.
	node.position = Vector2(50, 20)
	mgr.call("update_arrows_for_element", node)

	var updated_pts: Variant = arrow.get("_cached_bezier_points")
	# Start should now be (57, 24).
	assert_vector(updated_pts[0]).is_equal(Vector2(57.0, 24.0))

	node.queue_free()
	shape.queue_free()
	await get_tree().process_frame
	var main: Node = scene["main"]
	main.queue_free()
	await get_tree().process_frame
