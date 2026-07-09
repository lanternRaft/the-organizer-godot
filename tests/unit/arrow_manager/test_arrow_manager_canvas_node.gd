extends GdUnitTestSuite

var arrow_manager: ArrowManager
var element_layer: Node2D
var click_handler: Node
var runner: GdUnitSceneRunner # 1. Keep the runner alive at class level!

const CANVAS_NODE_SCENE: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
const ARROW_SCENE: PackedScene = preload("res://scenes/tools/arrow/arrow.tscn")


# ----- Helpers ---------------------------------------------------------------
func before_test() -> void:
	_create_test_scene()

## Creates a minimal test scene with ElementLayer and AnchorLayer
## ArrowManager is added as a child of Main.
func _create_test_scene() -> void:
	# Build the tree structure expected by ArrowManager and ClickHandler @onready vars.
	# The @onready var element_layer := %ElementLayer uses get_node("%ElementLayer") which
	# searches up the owner chain.  We must set owner explicitly so % can find the nodes.
	var main: Main = auto_free(Main.new())
	
	var canvas: Node2D = auto_free(Node2D.new())
	canvas.name = "Canvas"

	element_layer = auto_free(Node2D.new())
	element_layer.name = "ElementLayer"
	element_layer.unique_name_in_owner = true
	element_layer.owner = main
	canvas.add_child(element_layer)


	var anchor_layer: Node2D = auto_free(Node2D.new())
	anchor_layer.name = "AnchorLayer"
	anchor_layer.unique_name_in_owner = true
	anchor_layer.owner = main
	canvas.add_child(anchor_layer)

	# Create a ClickHandler stub so ArrowManager doesn't error on get_parent().get_node("ClickHandler").
	click_handler = auto_free(Node.new())
	click_handler.name = "ClickHandler"
	main.add_child(click_handler)

	# Add the full tree to the scene (triggers @onready and _ready on all children).
	main.add_child(canvas)
	
	arrow_manager = auto_free(ArrowManager.new())
	main.add_child(arrow_manager)
	runner = scene_runner(main)

	runner.simulate_frames(1)


## Creates a CanvasNode circle at the given position and adds it to element_layer.
func _create_circle_node(position: Vector2) -> CanvasNode:
	var node: CanvasNode = auto_free(CANVAS_NODE_SCENE.instantiate())
	node.set("sub_mode", "circle_node")
	node.position = position
	element_layer.add_child(node)
	return node


## Creates a LabelShape oval at the given position and adds it to element_layer.
func _create_label_shape(position: Vector2) -> CanvasElement:
	var shape: CanvasElement = auto_free(LABEL_SHAPE_SCENE.instantiate())
	shape.set("rx", 80.0)
	shape.set("ry", 50.0)
	shape.position = position
	element_layer.add_child(shape)
	return shape


func test_arrow_shape_to_circle_node() -> void:
	var shape: CanvasElement = _create_label_shape(Vector2(0, 0))
	var node: CanvasNode = _create_circle_node(Vector2(200, 0))
	await get_tree().process_frame

	arrow_manager._create_arrow(shape, "right", node, "left")

	var arrows: Array = arrow_manager._arrows
	assert_int(arrows.size()).is_equal(1)

	var arrow: Arrow = arrows[0]
	assert_error(func() -> void: arrow.rebuild_path()).is_success()

	assert_str(arrow.start_anchor_label).is_equal("right")
	assert_str(arrow.end_anchor_label).is_equal("left")
