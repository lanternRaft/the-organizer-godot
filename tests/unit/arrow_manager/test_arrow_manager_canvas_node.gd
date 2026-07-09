extends GdUnitTestSuite

var arrow_manager: ArrowManager
var element_layer: Node2D
var click_handler: Node
var runner: GdUnitSceneRunner # 1. Keep the runner alive at class level!

const CANVAS_NODE_SCENE: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")

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

	arrow_manager = auto_free(ArrowManager.new())
	main.add_child(arrow_manager)
	arrow_manager.owner = main

	runner = scene_runner(main)


func _create_circle_node(position: Vector2) -> CanvasNode:
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


func test_arrow_shape_to_circle_node() -> void:
	var shape: LabelShape = _create_label_shape(Vector2(0, 0))
	var node: CanvasNode = _create_circle_node(Vector2(200, 0))

	arrow_manager._create_arrow(shape, "right", node, "left")

	var arrows: Array = arrow_manager._arrows
	assert_int(arrows.size()).is_equal(1)

	var arrow: Arrow = arrows[0]
	assert_error(func() -> void: arrow.rebuild_path()).is_success()

	assert_str(arrow.start_anchor_label).is_equal("right")
	assert_str(arrow.end_anchor_label).is_equal("left")
