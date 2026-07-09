# GdUnit generated TestSuite
class_name ClickHandlerDiscoveryTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")
@warning_ignore("unsafe_method_access")
@warning_ignore("unsafe_property_access")

# TestSuite generated from
const __source: String = "res://scenes/main/click_handler/click_handler.gd"

const CLICK_HANDLER_SCRIPT: GDScript = preload("res://scenes/main/click_handler/click_handler.gd")
const TRACKER_SCRIPT: GDScript = preload(
	"res://tests/unit/main/click_handler/test_click_handler_tracker.gd"
)

# ----- Typed helpers ---------------------------------------------------------


## Typed scene container so we never access Dictionary values as Variant.
class TestScene:
	var element_layer: Node2D
	var click_handler: Node
	var root: Node


## Creates a minimal test scene with ElementLayer and ClickHandler.
## Sets element_layer directly on the click_handler to bypass the
## %ElementLayer unique-name lookup (which requires a full scene tree
## with proper owner chain).
func _create_test_scene() -> TestScene:
	var root: Node = Node.new()
	get_tree().root.add_child(root)

	var element_layer: Node2D = Node2D.new()
	element_layer.name = "ElementLayer"
	root.add_child(element_layer)
	element_layer.owner = root

	var click_handler: Node = Node.new()
	click_handler.name = "ClickHandler"
	click_handler.set_script(CLICK_HANDLER_SCRIPT)
	root.add_child(click_handler)
	click_handler.owner = root

	# Wait a frame so that @onready vars run (they will fail for %ElementLayer,
	# but we override it immediately after).
	await get_tree().process_frame

	# Bypass the %ElementLayer lookup by setting the property directly.
	click_handler.set("element_layer", element_layer)

	var result: TestScene = TestScene.new()
	result.element_layer = element_layer
	result.click_handler = click_handler
	result.root = root
	return result


## Creates a dummy element node that belongs to a group.
## If add_handle_click is true, also defines a minimal handle_click method.
func _create_grouped_element(
	element_layer: Node2D, group: String, add_area: bool = true
) -> ClickTracker:
	var node: ClickTracker = ClickTracker.new()
	node.name = "TestElement"

	if add_area:
		var area: Area2D = Area2D.new()
		area.name = "Area2D"
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.set("extents", Vector2(50, 50))
		collision.set("shape", shape)
		area.add_child(collision)
		node.add_child(area)

	if group:
		node.add_to_group(group)

	# ClickTracker already has handle_click (sets was_called) and was_called
	# property — no script override needed.

	element_layer.add_child(node)
	return node


## Creates a script with handle_click method for fallback testing.
func _create_handle_click_script() -> GDScript:
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Node2D
func handle_click(_event: Dictionary) -> bool:
	return true
"""
	script.reload()
	return script


## Creates a script without handle_click method (for non-clickable nodes).
func _create_dummy_script() -> GDScript:
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Node2D
"""
	script.reload()
	return script


## Triggers _unhandled_input with a left-button press at world_pos.
func _click_at(click_handler: Node, world_pos: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.global_position = world_pos
	event.position = world_pos
	click_handler.call("_unhandled_input", event)


# ===== test_discovery_via_group ============================================


## ClickHandler discovers elements via clickable_element group.
## Creates an element in the "clickable_element" group with handle_click,
## clicks at its position, and verifies that the click handler dispatches
## to the element (by checking that the element's handle_click was called).
func test_discovery_via_group() -> void:
	var scene: TestScene = await _create_test_scene()
	var el: Node2D = scene.element_layer
	var click_handler: Node = scene.click_handler

	# Create an element in the "clickable_element" group with handle_click method.
	var element: ClickTracker = _create_grouped_element(el, "clickable_element", true)
	await get_tree().process_frame

	# Click at the element's position.
	var world_pos: Vector2 = element.global_position
	_click_at(click_handler, world_pos)
	await get_tree().process_frame

	# The handle_click should have been called (was_called set to true).
	assert_bool(element.was_called).is_true()

	scene.root.queue_free()
	await get_tree().process_frame


# ===== test_discovery_ignores_unknown_nodes =================================


## Non-grouped nodes without handle_click are ignored.
## Creates a node NOT in clickable_element group and WITHOUT handle_click method,
## clicks at its position, and verifies that empty_canvas_clicked is emitted
## instead (the node is not discovered as a clickable element).
func test_discovery_ignores_unknown_nodes() -> void:
	var scene: TestScene = await _create_test_scene()
	var el: Node2D = scene.element_layer
	var click_handler: Node = scene.click_handler

	# Create an element with an Area2D but NO handle_click and NO group membership.
	var element: Node2D = Node2D.new()
	element.name = "UnknownElement"

	var area: Area2D = Area2D.new()
	area.name = "Area2D"
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.set("extents", Vector2(50, 50))
	collision.set("shape", shape)
	area.add_child(collision)
	element.add_child(area)

	el.add_child(element)
	await get_tree().process_frame

	# Track whether empty_canvas_clicked was emitted.
	# Use signal connection via string name to avoid type issues.
	var empty_clicked: Array[bool] = [false]
	if click_handler.has_signal("empty_canvas_clicked"):
		click_handler.connect(
			"empty_canvas_clicked", Callable(func(_pos: Vector2) -> void: empty_clicked[0] = true)
		)

	# Click at the element's position.
	var world_pos: Vector2 = element.global_position
	_click_at(click_handler, world_pos)
	await get_tree().process_frame

	# The unknown node should not be discovered, so empty_canvas_clicked fires.
	assert_bool(empty_clicked[0]).is_true()

	scene.root.queue_free()
	await get_tree().process_frame
