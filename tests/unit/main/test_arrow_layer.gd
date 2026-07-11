extends GdUnitTestSuite

const CANVAS_NODE_SCENE: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")

var arrow_layer: ArrowLayer
var element_layer: Node2D
var click_handler: Node
var toolbar: Toolbar
var runner: GdUnitSceneRunner


func before_test() -> void:
	_create_test_scene()


func _create_test_scene() -> void:
	var main: Main = auto_free(Main.new())

	var canvas: Node2D = auto_free(Node2D.new())
	canvas.name = "Canvas"
	main.add_child(canvas)

	element_layer = auto_free(Node2D.new())
	element_layer.name = "ElementLayer"
	element_layer.unique_name_in_owner = true
	canvas.add_child(element_layer)
	element_layer.owner = main

	var anchor_layer: Node2D = auto_free(Node2D.new())
	anchor_layer.name = "AnchorLayer"
	anchor_layer.unique_name_in_owner = true
	canvas.add_child(anchor_layer)
	anchor_layer.owner = main

	click_handler = auto_free(Node.new())
	click_handler.name = "ClickHandler"
	main.add_child(click_handler)
	click_handler.owner = main

	toolbar = auto_free(Toolbar.new())
	toolbar.name = "Toolbar"
	toolbar.unique_name_in_owner = true
	canvas.add_child(toolbar)
	toolbar.owner = main

	arrow_layer = auto_free(ArrowLayer.new())
	main.add_child(arrow_layer)
	arrow_layer.owner = main

	runner = scene_runner(main)


func _create_canvas_node(position: Vector2) -> CanvasNode:
	var node: CanvasNode = auto_free(CANVAS_NODE_SCENE.instantiate())
	node.sub_mode = "circle_node"
	node.position = position
	element_layer.add_child(node)
	return node


func _create_label_shape(position: Vector2) -> LabelShape:
	var shape: LabelShape = auto_free(LABEL_SHAPE_SCENE.instantiate())
	shape.rx = 80.0
	shape.ry = 50.0
	shape.position = position
	element_layer.add_child(shape)
	return shape


func test_arrow_label_shape_to_canvas_node() -> void:
	var shape: LabelShape = _create_label_shape(Vector2(0, 0))
	var node: CanvasNode = _create_canvas_node(Vector2(200, 0))

	arrow_layer._create_arrow(shape, "right", node, "left")

	assert_int(arrow_layer._arrows.size()).is_equal(1)

	var arrow: Arrow = arrow_layer._arrows[0]
	assert_error(func() -> void: arrow.rebuild_path()).is_success()

	assert_str(arrow.start_anchor_label).is_equal("right")
	assert_str(arrow.end_anchor_label).is_equal("left")


func test_arrow_canvas_node_to_canvas_node() -> void:
	var circle: CanvasNode = _create_canvas_node(Vector2(0, 0))
	var triangle: CanvasNode = CANVAS_NODE_SCENE.instantiate()
	triangle.sub_mode = "triangle_node"
	triangle.position = Vector2(200, 0)
	element_layer.add_child(triangle)

	arrow_layer._create_arrow(circle, "right", triangle, "bottom_left")

	assert_int(arrow_layer._arrows.size()).is_equal(1)

	var arrow: Arrow = arrow_layer._arrows[0]
	assert_error(func() -> void: arrow.rebuild_path()).is_success()
	assert_str(arrow.get("start_anchor_label")).is_equal("right")
	assert_str(arrow.get("end_anchor_label")).is_equal("bottom_left")


func test_arrow_label_shape_to_label_shape() -> void:
	var shape_1: LabelShape = _create_label_shape(Vector2(0, 0))
	var shape_2: LabelShape = _create_label_shape(Vector2(200, 0))

	arrow_layer._create_arrow(shape_1, "right", shape_2, "left")

	assert_int(arrow_layer._arrows.size()).is_equal(1)

	var arrow: Arrow = arrow_layer._arrows[0]
	assert_error(func() -> void: arrow.rebuild_path()).is_success()

	assert_str(arrow.start_anchor_label).is_equal("right")
	assert_str(arrow.end_anchor_label).is_equal("left")


func test_arrow_self_connection_node() -> void:
	var node: CanvasNode = _create_canvas_node(Vector2(100, 100))
	await get_tree().process_frame

	var initial_count: int = arrow_layer._arrows.size()

	# Simulate arrow drag from node's "top" released on same node's "bottom".
	# ArrowManager's end_arrow_drag checks _drag_snapped_element != _drag_start_element,
	# so setting both to the same node should prevent creation.
	arrow_layer._drag_start_element = node
	arrow_layer._drag_start_label = "top"
	arrow_layer._drag_snapped_element = node
	arrow_layer._drag_snapped_label = "bottom"
	arrow_layer.end_arrow_drag()

	assert_int(arrow_layer._arrows.size()).is_equal(initial_count)


func test_delete_node_removes_arrows() -> void:
	var shape: LabelShape = _create_label_shape(Vector2(0, 0))
	var node: CanvasNode = _create_canvas_node(Vector2(200, 0))

	arrow_layer._create_arrow(shape, "right", node, "left")
	assert_int(arrow_layer._arrows.size()).is_equal(1)

	arrow_layer.delete_arrows_for_element(node)

	assert_int(arrow_layer._arrows.size()).is_equal(0)


func test_arrow_drag_from_node_shows_preview() -> void:
	var node: CanvasNode = _create_canvas_node(Vector2(100, 100))

	var top_pos: Vector2 = node.get_anchor_position("top")

	# Call handle_dot_mousedown at the top anchor position.
	var result: bool = arrow_layer.handle_dot_mousedown(top_pos)

	assert_bool(result).is_true()
	assert_bool(arrow_layer._arrow_drag_active).is_true()
	assert_object(arrow_layer._drag_start_element).is_same(node)
	assert_str(arrow_layer._drag_start_label).is_equal("top")
	# Preview arrow should exist.
	assert_bool(arrow_layer._preview_arrow != null).is_true()


func test_arrow_drag_no_snap_discards() -> void:
	var node: CanvasNode = _create_canvas_node(Vector2(100, 100))

	var top_pos: Vector2 = node.get_anchor_position("top")

	# Begin drag.
	arrow_layer.handle_dot_mousedown(top_pos)
	assert_bool(arrow_layer._arrow_drag_active).is_true()

	# End drag without snapping (drag_snapped_element is null).
	arrow_layer.end_arrow_drag()

	assert_bool(arrow_layer._arrow_drag_active).is_false()
	assert_int(arrow_layer._arrows.size()).is_equal(0)
		(
			assert_bool(
				arrow_layer._preview_arrow == null or not is_instance_valid(arrow_layer._preview_arrow)
			)
			. is_true()
		)


func test_arrow_updates_on_node_move() -> void:
	var shape: LabelShape = _create_label_shape(Vector2(0, 0))
	var node: CanvasNode = _create_canvas_node(Vector2(200, 0))

	arrow_layer._create_arrow(shape, "right", node, "left")
	var arrow: Arrow = arrow_layer._arrows[0]
	arrow.rebuild_path()

	# Cache original bezier points.
	var original_points: PackedVector2Array = arrow._cached_bezier_points

	# Move node to a new position.
	node.position = Vector2(300, 50)
	await get_tree().process_frame

	# Update arrows for the moved node (using new method name).
	arrow_layer.update_arrows_for_element(node)

	var updated_points: PackedVector2Array = arrow.get("_cached_bezier_points")
	# Points should have changed.
	assert_array(original_points).is_not_equal(updated_points)
