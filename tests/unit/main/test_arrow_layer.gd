extends GdUnitTestSuite

const CIRCLE_NODE_SCENE: PackedScene = preload("res://scenes/canvas_elements/circle_node.tscn")
const TRIANGLE_NODE_SCENE: PackedScene = preload("res://scenes/canvas_elements/triangle_node.tscn")

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
	var node: CanvasNode = auto_free(CIRCLE_NODE_SCENE.instantiate())
	node.position = position
	element_layer.add_child(node)
	return node


func test_arrow_canvas_node_to_canvas_node() -> void:
	var circle: CanvasNode = _create_canvas_node(Vector2(0, 0))
	var triangle: CanvasNode = TRIANGLE_NODE_SCENE.instantiate()
	triangle.position = Vector2(200, 0)
	element_layer.add_child(triangle)

	arrow_layer._create_arrow(circle.line_anchors[0], triangle.line_anchors[0])

	assert_int(arrow_layer.get_children().size()).is_equal(1)

	var arrow: Arrow = arrow_layer.get_children()[0]
	assert_error(func() -> void: arrow.rebuild_path()).is_success()
	assert_object(arrow.start_anchor.canvas_element).is_same(circle)
	assert_object(arrow.end_anchor.canvas_element).is_same(triangle)


func test_arrow_self_connection_node() -> void:
	var node: CanvasNode = _create_canvas_node(Vector2(100, 100))
	await get_tree().process_frame

	var initial_count: int = arrow_layer.get_children().size()

	# Simulate arrow drag from node's "top" released on same node's "bottom".
	# ArrowManager's end_arrow_drag checks _drag_snapped_element != _drag_start_element,
	# so setting both to the same node should prevent creation.
	arrow_layer._drag_start_anchor = node.line_anchors[0]
	arrow_layer._drag_snapped_anchor = node.line_anchors[1]
	arrow_layer._line_drag_stop()

	assert_int(arrow_layer.get_children().size()).is_equal(initial_count)
