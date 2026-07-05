# GdUnit generated TestSuite
class_name ClickHandlerDiscoveryTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/main/click_handler/click_handler.gd'

const CLICK_HANDLER_SCRIPT: GDScript = preload("res://scenes/main/click_handler/click_handler.gd")

# ----- Helpers ---------------------------------------------------------------

## Creates a minimal test scene with ElementLayer and ClickHandler.
## Returns { "element_layer": Node2D, "click_handler": Node }
func _create_test_scene() -> Dictionary:
	var root: Node = Node.new()
	get_tree().root.add_child(root)

	var element_layer: Node2D = Node2D.new()
	element_layer.name = "ElementLayer"
	element_layer.unique_name_in_owner = true
	root.add_child(element_layer)
	element_layer.owner = root

	var click_handler: Node = Node.new()
	click_handler.name = "ClickHandler"
	click_handler.set_script(CLICK_HANDLER_SCRIPT)
	root.add_child(click_handler)
	click_handler.owner = root

	# Make the ClickHandler process frame so @onready vars resolve.
	await get_tree().process_frame

	return {
		"element_layer": element_layer,
		"click_handler": click_handler,
		"root": root,
	}


## Creates a dummy element node that belongs to a group.
## If add_handle_click is true, also defines a minimal handle_click method.
func _create_grouped_element(
	element_layer: Node2D,
	group: String,
	add_handle_click: bool = false,
	add_area: bool = true
) -> Node2D:
	var node: Node2D = Node2D.new()
	node.name = "TestElement"

	if add_area:
		var area: Area2D = Area2D.new()
		area.name = "Area2D"
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.extents = Vector2(50, 50)
		collision.shape = shape
		area.add_child(collision)
		node.add_child(area)

	if group:
		node.add_to_group(group)

	if add_handle_click:
		node.set_script(_create_handle_click_script())

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


## Simulates a left-click at the given world position.
func _simulate_click(click_handler: Node, world_pos: Vector2) -> void:
	# Call _handle_pointer_down directly to avoid needing a full InputEvent setup.
	# We pass a minimal InputEventMouseButton through the event system.
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.global_position = world_pos
	event.position = world_pos
	click_handler.call("_handle_pointer_down", event)


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
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var click_handler: Node = scene["click_handler"]

	# Create an element in the "clickable_element" group with handle_click method.
	var element: Node2D = _create_grouped_element(el, "clickable_element", true, true)
	await get_tree().process_frame

	# Track whether handle_click was called.
	var called: bool = false
	var original_script: GDScript = element.get_script()
	# Override handle_click to track invocation.
	var tracker_script: GDScript = GDScript.new()
	tracker_script.source_code = """
extends Node2D
var was_called := false
func handle_click(_event: Dictionary) -> bool:
	was_called = true
	return true
"""
	tracker_script.reload()
	element.set_script(tracker_script)

	# Click at the element's position.
	var world_pos: Vector2 = element.global_position
	_click_at(click_handler, world_pos)
	await get_tree().process_frame

	# The handle_click should have been called (was_called set to true).
	assert_bool(element.get("was_called")).is_true()

	# Cleanup.
	element.set_script(original_script)
	scene["root"].queue_free()
	await get_tree().process_frame


# ===== test_discovery_fallback_has_method ===================================

## ClickHandler falls back to has_method for legacy nodes (no group membership).
## Creates an element NOT in the "clickable_element" group but WITH a handle_click
## method, clicks at its position, and verifies the click is still dispatched.
func test_discovery_fallback_has_method() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var click_handler: Node = scene["click_handler"]

	# Create an element NOT in clickable_element group but WITH handle_click.
	var element: Node2D = Node2D.new()
	element.name = "LegacyElement"

	var area: Area2D = Area2D.new()
	area.name = "Area2D"
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.extents = Vector2(50, 50)
	collision.shape = shape
	area.add_child(collision)
	element.add_child(area)

	# Give it a handle_click method via script.
	var legacy_script: GDScript = GDScript.new()
	legacy_script.source_code = """
extends Node2D
var was_called := false
func handle_click(_event: Dictionary) -> bool:
	was_called = true
	return true
"""
	legacy_script.reload()
	element.set_script(legacy_script)

	# Do NOT add to "clickable_element" group.
	el.add_child(element)
	await get_tree().process_frame

	# Click at the element's position.
	var world_pos: Vector2 = element.global_position
	_click_at(click_handler, world_pos)
	await get_tree().process_frame

	# handle_click should still be called via fallback.
	assert_bool(element.get("was_called")).is_true()

	scene["root"].queue_free()
	await get_tree().process_frame


# ===== test_discovery_ignores_unknown_nodes =================================

## Non-grouped nodes without handle_click are ignored.
## Creates a node NOT in clickable_element group and WITHOUT handle_click method,
## clicks at its position, and verifies that empty_canvas_clicked is emitted
## instead (the node is not discovered as a clickable element).
func test_discovery_ignores_unknown_nodes() -> void:
	var scene: Dictionary = await _create_test_scene()
	var el: Node2D = scene["element_layer"]
	var click_handler: Node = scene["click_handler"]

	# Create an element with an Area2D but NO handle_click and NO group membership.
	var element: Node2D = Node2D.new()
	element.name = "UnknownElement"

	var area: Area2D = Area2D.new()
	area.name = "Area2D"
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.extents = Vector2(50, 50)
	collision.shape = shape
	area.add_child(collision)
	element.add_child(area)

	el.add_child(element)
	await get_tree().process_frame

	# Track whether empty_canvas_clicked was emitted.
	var empty_clicked: bool = false
	click_handler.empty_canvas_clicked.connect(func(_pos: Vector2) -> void:
		empty_clicked = true
	)

	# Click at the element's position.
	var world_pos: Vector2 = element.global_position
	_click_at(click_handler, world_pos)
	await get_tree().process_frame

	# The unknown node should not be discovered, so empty_canvas_clicked fires.
	assert_bool(empty_clicked).is_true()

	scene["root"].queue_free()
	await get_tree().process_frame