# GdUnit generated TestSuite
class_name ClickHandlerAnchorPriorityTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")
@warning_ignore("unsafe_method_access")
@warning_ignore("unsafe_property_access")

# TestSuite generated from
const __source: String = "res://scenes/main/click_handler/click_handler.gd"

const CLICK_HANDLER_SCRIPT: GDScript = preload("res://scenes/main/click_handler/click_handler.gd")

# ----- Helpers ---------------------------------------------------------------


## Creates a minimal test scene with ElementLayer and ClickHandler.
## Returns { "element_layer": Node2D, "click_handler": Node, "root": Node }
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


## Creates a mock Main script that tracks calls to anchor dot and arrow handlers.
## The mock is placed on the parent node of the click handler.
func _create_mock_main(anchor_returns: bool, arrow_returns: bool) -> GDScript:
	var script: GDScript = GDScript.new()
	script.source_code = (
		"""extends Node

var anchor_called := false
var arrow_called := false

func _on_anchor_dot_mousedown(_world_pos: Vector2) -> bool:
	anchor_called = true
	return %s

func _on_arrow_clicked_at(_world_pos: Vector2) -> bool:
	arrow_called = true
	return %s
"""
		% ["true" if anchor_returns else "false", "true" if arrow_returns else "false"]
	)
	script.reload()
	return script


## Simulates a left-button press at world_pos via _unhandled_input.
func _click_at(click_handler: Node, world_pos: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.global_position = world_pos
	event.position = world_pos
	click_handler.call("_unhandled_input", event)


# ===== test_anchor_dot_priority_over_arrow ===================================


## Anchor dot takes priority over arrow endpoint at same position.
## Sets up a mock Main with both _on_anchor_dot_mousedown and _on_arrow_clicked_at.
## Verifies that when both methods would match at the same position, the anchor
## dot handler is called and the arrow handler is NOT called.
func test_anchor_dot_priority_over_arrow() -> void:
	var scene: Dictionary = await _create_test_scene()
	var click_handler: Node = scene["click_handler"]
	var root: Node = scene["root"]

	# Mock Main: anchor returns true (handled), arrow returns true (would handle).
	root.set_script(_create_mock_main(true, true))
	await get_tree().process_frame

	# Click at some arbitrary position.
	_click_at(click_handler, Vector2(100, 100))
	await get_tree().process_frame

	# Anchor dot handler should have been called (returns true, so handled).
	assert_bool(root.get("anchor_called")).is_true()
	# Arrow handler should NOT have been called because anchor dot handled it.
	assert_bool(root.get("arrow_called")).is_false()

	root.queue_free()
	await get_tree().process_frame


# ===== test_click_anchor_dot_starts_arrow_drag ===============================


## Click on anchor dot with connected arrow starts arrow drag.
## Verifies that _on_anchor_dot_mousedown is called when clicking on an
## anchor dot position, even if an arrow endpoint is also present.
func test_click_anchor_dot_starts_arrow_drag() -> void:
	var scene: Dictionary = await _create_test_scene()
	var click_handler: Node = scene["click_handler"]
	var root: Node = scene["root"]

	# Mock Main: anchor returns true (handled), arrow returns true (would handle).
	root.set_script(_create_mock_main(true, true))
	await get_tree().process_frame

	# Click at a position that would be an anchor dot.
	_click_at(click_handler, Vector2(200, 200))
	await get_tree().process_frame

	# Anchor dot handler should be called first.
	assert_bool(root.get("anchor_called")).is_true()
	# Arrow handler should not be called since anchor dot handled the click.
	assert_bool(root.get("arrow_called")).is_false()

	root.queue_free()
	await get_tree().process_frame


# ===== test_arrow_body_selection_unaffected ==================================


## Click on arrow body (away from anchors) still selects arrow.
## When the anchor dot handler does NOT handle the click (returns false),
## the arrow handler should still be reached.
func test_arrow_body_selection_unaffected() -> void:
	var scene: Dictionary = await _create_test_scene()
	var click_handler: Node = scene["click_handler"]
	var root: Node = scene["root"]

	# Mock Main: anchor returns false (not found), arrow returns true (handled).
	root.set_script(_create_mock_main(false, true))
	await get_tree().process_frame

	# Click at some position (no anchor dot there, but arrow body is present).
	_click_at(click_handler, Vector2(300, 150))
	await get_tree().process_frame

	# Anchor dot handler was called but returned false (not handled).
	assert_bool(root.get("anchor_called")).is_true()
	# Arrow handler should have been called since anchor dot didn't handle.
	assert_bool(root.get("arrow_called")).is_true()

	root.queue_free()
	await get_tree().process_frame


# ===== test_empty_canvas_unchanged ===========================================


## Click on empty canvas still emits empty_canvas_clicked.
## When neither anchor dot nor arrow handler handle the click, the
## empty_canvas_clicked signal should still fire.
func test_empty_canvas_unchanged() -> void:
	var scene: Dictionary = await _create_test_scene()
	var click_handler: Node = scene["click_handler"]
	var root: Node = scene["root"]

	# Mock Main: both handlers return false (nothing found).
	root.set_script(_create_mock_main(false, false))
	await get_tree().process_frame

	# Track whether empty_canvas_clicked was emitted (use array for ref capture).
	var empty_clicked: Array[bool] = [false]
	# Use string-based connect to avoid static analysis issues.
	click_handler.connect(
		"empty_canvas_clicked", func(_pos: Vector2) -> void: empty_clicked[0] = true
	)

	# Click at some position where nothing is found.
	_click_at(click_handler, Vector2(400, 250))
	await get_tree().process_frame

	# Both handlers were called but neither handled the click.
	assert_bool(root.get("anchor_called")).is_true()
	assert_bool(root.get("arrow_called")).is_true()
	# Empty canvas signal should have been emitted.
	assert_bool(empty_clicked[0]).is_true()

	root.queue_free()
	await get_tree().process_frame
