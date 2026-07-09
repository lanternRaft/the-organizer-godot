# GdUnit generated TestSuite
class_name CanvasNodeBaseTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")

# TestSuite generated from
const __source: String = "res://scenes/tools/canvas_node/canvas_node.gd"
const __scene: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")

const CIRCLE_RADIUS: float = 8.0
const GRID_SIZE: float = 20.0

# ----- Helpers ---------------------------------------------------------------


## Instantiates a CanvasNode, adds to tree, and returns it.
func _create_node(sub_mode: String = "circle_node") -> CanvasNode:
	var node: CanvasNode = __scene.instantiate()
	node.sub_mode = sub_mode
	get_tree().root.add_child(node)
	await get_tree().process_frame
	return node


## Simulates a pointer event dictionary.
func _make_pointer_event(
	world_pos: Vector2 = Vector2.ZERO, local_pos: Vector2 = Vector2.ZERO
) -> Dictionary:
	return {
		"world_pos": world_pos,
		"local_pos": local_pos,
		"pressed": true,
		"dragged": false,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": InputEventMouseButton.new(),
	}


# ===== CanvasNode is an instance of CanvasElement ==========================


func test_canvas_node_is_canvas_element() -> void:
	var node: CanvasNode = await _create_node("circle_node")
	assert_bool(node is CanvasElement).is_true()
	assert_bool(node is Node2D).is_true()
	node.free()


# ===== CanvasNode inherits set_selected from base ===========================


func test_canvas_node_inherits_set_selected() -> void:
	var node: CanvasNode = await _create_node("circle_node")

	# set_selected should exist and be callable.
	assert_bool(node.has_method("set_selected")).is_true()

	assert_bool(node.is_selected).is_false()

	node.set_selected(true)
	assert_bool(node.is_selected).is_true()
	assert_bool(node.is_primary).is_false()

	node.is_primary = true
	node.set_selected(false)
	assert_bool(node.is_selected).is_false()
	assert_bool(node.is_primary).is_false()

	node.free()


# ===== CanvasNode get_anchor_positions returns 4 for circle sub_mode ========


func test_canvas_node_circle_anchors() -> void:
	var node: CanvasNode = await _create_node("circle_node")
	node.position = Vector2(100, 200)
	await get_tree().process_frame

	var anchors: Array[Dictionary] = node.get_anchor_positions()
	assert_int(anchors.size()).is_equal(4)

	# Each entry has a "label" and "offset" key.
	var labels: Array[String] = []
	for entry: Dictionary in anchors:
		assert_bool(entry.has("label")).is_true()
		assert_bool(entry.has("offset")).is_true()
		labels.append(entry["label"])

	assert_array(labels).contains(["top", "bottom", "left", "right"])

	# Offsets are local, not global.
	for entry: Dictionary in anchors:
		match entry["label"]:
			"top":
				assert_vector(entry["offset"]).is_equal_approx(Vector2(0, -8), Vector2(0.5, 0.5))
			"bottom":
				assert_vector(entry["offset"]).is_equal_approx(Vector2(0, 8), Vector2(0.5, 0.5))
			"left":
				assert_vector(entry["offset"]).is_equal_approx(Vector2(-8, 0), Vector2(0.5, 0.5))
			"right":
				assert_vector(entry["offset"]).is_equal_approx(Vector2(8, 0), Vector2(0.5, 0.5))

	node.free()


# ===== CanvasNode get_anchor_positions returns 3 for triangle sub_mode ======


func test_canvas_node_triangle_anchors() -> void:
	var node: CanvasNode = await _create_node("triangle_node")
	node.position = Vector2(100, 200)
	await get_tree().process_frame

	var anchors: Array[Dictionary] = node.get_anchor_positions()
	assert_int(anchors.size()).is_equal(3)

	var labels: Array[String] = []
	for entry: Dictionary in anchors:
		assert_bool(entry.has("label")).is_true()
		assert_bool(entry.has("offset")).is_true()
		labels.append(entry["label"])

	assert_array(labels).contains(["top", "bottom_left", "bottom_right"])

	for entry: Dictionary in anchors:
		match entry["label"]:
			"top":
				assert_vector(entry["offset"]).is_equal_approx(Vector2(0, -8), Vector2(0.5, 0.5))
			"bottom_left":
				assert_vector(entry["offset"]).is_equal_approx(Vector2(-7, 4), Vector2(0.5, 0.5))
			"bottom_right":
				assert_vector(entry["offset"]).is_equal_approx(Vector2(7, 4), Vector2(0.5, 0.5))

	node.free()


# ===== CanvasNode handle_click sets drag_mode body and emits clicked ========


func test_canvas_node_handle_click_body_mode() -> void:
	var node: CanvasNode = await _create_node("circle_node")

	var signal_data: Dictionary = {"fired": false, "ref": null}
	node.clicked.connect(
		func(_event: InputEvent, el: Node) -> void:
			signal_data["fired"] = true
			signal_data["ref"] = el
	)

	var event: Dictionary = _make_pointer_event(Vector2(50, 50))
	var result: bool = node.handle_click(event)

	assert_bool(result).is_true()
	assert_str(node._drag_mode).is_equal("body")
	assert_bool(signal_data["fired"]).is_true()
	assert_object(signal_data["ref"]).is_same(node)

	node.free()


# ===== CanvasNode handle_double_click returns true as no-op =================


func test_canvas_node_double_click_noop() -> void:
	var node: CanvasNode = await _create_node("circle_node")

	# No double_clicked signal exists on CanvasNode.
	assert_bool(node.has_signal("double_clicked")).is_false()

	# The method exists and returns true without doing anything observable.
	var result: bool = node.handle_double_click({})
	assert_bool(result).is_true()

	node.free()


# ===== CanvasNode supports_text_editing returns false =======================


func test_canvas_node_supports_text_editing() -> void:
	var node: CanvasNode = await _create_node("circle_node")

	assert_bool(node.supports_text_editing()).is_false()

	node.free()


# ===== CanvasNode shows_in_legend returns false =============================


func test_canvas_node_shows_in_legend() -> void:
	var node: CanvasNode = await _create_node("circle_node")

	assert_bool(node.shows_in_legend()).is_false()

	node.free()


# ===== CanvasNode drag lifecycle uses inherited base methods ================


func test_canvas_node_drag_uses_inherited_logic() -> void:
	var node: CanvasNode = await _create_node("circle_node")
	node.is_selected = true
	node.position = Vector2(100, 100)

	# --- Drag begin ---
	var begin_result: bool = node.handle_drag_begin(_make_pointer_event(Vector2(100, 100)))
	assert_bool(begin_result).is_true()
	assert_str(node._drag_mode).is_equal("body")

	# --- Drag move ---
	var multi_signal: Dictionary = {"fired": false, "delta": Vector2.ZERO}
	node.multi_drag_moved.connect(
		func(d: Vector2) -> void:
			multi_signal["fired"] = true
			multi_signal["delta"] = d
	)

	node.handle_drag_move(_make_pointer_event(Vector2(130, 140)))

	assert_bool(multi_signal["fired"]).is_true()
	assert_vector(multi_signal["delta"]).is_equal_approx(Vector2(30, 40), Vector2(0.1, 0.1))
	assert_vector(node.position).is_equal_approx(Vector2(130, 140), Vector2(1.0, 1.0))

	# --- Drag end ---
	var end_signals: Dictionary = {"anchor_fired": false, "multi_ended_fired": false}
	node.anchor_changed.connect(func() -> void: end_signals["anchor_fired"] = true)
	node.multi_drag_ended.connect(func() -> void: end_signals["multi_ended_fired"] = true)

	# Move to non-snapped position then end drag.
	node.handle_drag_move(_make_pointer_event(Vector2(137, 152)))
	node.handle_drag_end(_make_pointer_event())

	# Position snapped to 20px grid (140, 160).
	assert_vector(node.position).is_equal(Vector2(140, 160))
	assert_bool(end_signals["anchor_fired"]).is_true()
	assert_bool(end_signals["multi_ended_fired"]).is_true()
	assert_str(node._drag_mode).is_equal("")

	node.free()
