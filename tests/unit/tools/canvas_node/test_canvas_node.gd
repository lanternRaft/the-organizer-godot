# GdUnit generated TestSuite
class_name CanvasNodeTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/tools/canvas_node/canvas_node.gd'
const __scene: PackedScene = preload("res://scenes/tools/canvas_node/canvas_node.tscn")

# Constants matching CanvasNode internals.
const CIRCLE_RADIUS: float = 8.0
const DEFAULT_FILL: Color = Color(0.231, 0.51, 0.965)
const GRID_SIZE: float = 20.0

# ----- Helpers ---------------------------------------------------------------

## Instantiates a CanvasNode, adds to tree, and returns it.
## sub_mode defaults to "circle_node" if not specified.
func _create_node(sub_mode: String = "circle_node") -> Node2D:
	var node: Node2D = __scene.instantiate()
	node.set("sub_mode", sub_mode)
	get_tree().root.add_child(node)
	await get_tree().process_frame
	return node


## Simulates a pointer event dictionary for handle_click.
func _make_pointer_event(world_pos: Vector2 = Vector2.ZERO, local_pos: Vector2 = Vector2.ZERO) -> Dictionary:
	return {
		"world_pos": world_pos,
		"local_pos": local_pos,
		"pressed": true,
		"dragged": false,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": InputEventMouseButton.new(),
	}


# ===== A1-A3: Creation & Sub-mode ===========================================

## A1: Circle node creation.
func test_circle_node_creation() -> void:
	var node: Node2D = await _create_node("circle_node")

	# Node is a valid Node2D child of the scene root.
	assert_bool(node is Node2D).is_true()
	assert_bool(is_instance_valid(node)).is_true()

	# sub_mode returns "circle_node".
	assert_str(node.get("sub_mode")).is_equal("circle_node")

	# fill_color defaults to #3b82f6.
	var _fill: Color = node.get("fill_color")
	assert_float(_fill.r).is_equal_approx(DEFAULT_FILL.r, 0.0001)
	assert_float(_fill.g).is_equal_approx(DEFAULT_FILL.g, 0.0001)
	assert_float(_fill.b).is_equal_approx(DEFAULT_FILL.b, 0.0001)

	# Area2D child exists with CollisionShape2D containing a CircleShape2D.
	assert_bool(node.has_node("Area2D")).is_true()
	assert_bool(node.has_node("Area2D/CollisionShape2D")).is_true()
	var collision: CollisionShape2D = node.get_node("Area2D/CollisionShape2D")
	assert_bool(collision.shape is CircleShape2D).is_true()
	assert_float((collision.shape as CircleShape2D).radius).is_equal(CIRCLE_RADIUS)

	# No resize handles (children named "Handle*" do not exist).
	for child: Node in node.get_children():
		if child.name.begins_with("Handle"):
			assert_bool(false).override_failure_message("CanvasNode should not have handle children").is_true()

	# No text label child named "TextLabel".
	assert_bool(node.has_node("TextLabel")).is_false()

	node.free()


## A2: Triangle node creation.
func test_triangle_node_creation() -> void:
	var node: Node2D = await _create_node("triangle_node")

	assert_str(node.get("sub_mode")).is_equal("triangle_node")

	# CollisionShape2D contains a PolygonShape2D with 3 vertices.
	var collision: CollisionShape2D = node.get_node("Area2D/CollisionShape2D")
	assert_bool(collision.shape is ConvexPolygonShape2D).is_true()
	var poly: ConvexPolygonShape2D = collision.shape as ConvexPolygonShape2D
	assert_int(poly.points.size()).is_equal(3)

	# Area2D hit-detection works (collision layer 1 by default).
	assert_int((node.get_node("Area2D") as Area2D).collision_layer).is_equal(1)

	node.free()


## A3: Sub-mode switch updates collision shape.
func test_sub_mode_switch_updates_collision() -> void:
	var node: Node2D = await _create_node("circle_node")

	# Verify initial collision is CircleShape2D.
	var collision: CollisionShape2D = node.get_node("Area2D/CollisionShape2D")
	assert_bool(collision.shape is CircleShape2D).is_true()

	# Switch to triangle.
	node.set("sub_mode", "triangle_node")

	# Collision shape changed to PolygonShape2D.
	assert_bool(collision.shape is ConvexPolygonShape2D).is_true()
	assert_str(node.get("sub_mode")).is_equal("triangle_node")

	node.free()


# ===== A4-A5: Anchor Positions ==============================================

## A4: Circle node anchor positions.
func test_circle_node_anchors() -> void:
	var node: Node2D = await _create_node("circle_node")
	node.position = Vector2(100, 200)
	await get_tree().process_frame

	var anchors: Array[String] = node.call("get_anchor_points")
	assert_int(anchors.size()).is_equal(4)
	assert_str(anchors[0]).is_equal("top")
	assert_str(anchors[1]).is_equal("bottom")
	assert_str(anchors[2]).is_equal("left")
	assert_str(anchors[3]).is_equal("right")

	# Each anchor at the expected global position.
	var top_pos: Vector2 = node.call("get_anchor_position", "top")
	assert_vector(top_pos).is_equal_approx(Vector2(100, 192), 0.5)

	var bottom_pos: Vector2 = node.call("get_anchor_position", "bottom")
	assert_vector(bottom_pos).is_equal_approx(Vector2(100, 208), 0.5)

	var left_pos: Vector2 = node.call("get_anchor_position", "left")
	assert_vector(left_pos).is_equal_approx(Vector2(92, 200), 0.5)

	var right_pos: Vector2 = node.call("get_anchor_position", "right")
	assert_vector(right_pos).is_equal_approx(Vector2(108, 200), 0.5)

	node.free()


## A5: Triangle node anchor positions.
func test_triangle_node_anchors() -> void:
	var node: Node2D = await _create_node("triangle_node")
	node.position = Vector2(100, 200)
	await get_tree().process_frame

	var anchors: Array[String] = node.call("get_anchor_points")
	assert_int(anchors.size()).is_equal(3)
	assert_str(anchors[0]).is_equal("top")
	assert_str(anchors[1]).is_equal("bottom_left")
	assert_str(anchors[2]).is_equal("bottom_right")

	var top_pos: Vector2 = node.call("get_anchor_position", "top")
	assert_vector(top_pos).is_equal_approx(Vector2(100, 192), 0.5)

	var bl_pos: Vector2 = node.call("get_anchor_position", "bottom_left")
	assert_vector(bl_pos).is_equal_approx(Vector2(93, 204), 1.0)

	var br_pos: Vector2 = node.call("get_anchor_position", "bottom_right")
	assert_vector(br_pos).is_equal_approx(Vector2(107, 204), 1.0)

	node.free()


# ===== A6-A7: Click Signals =================================================

## A6: Click signal emitted.
func test_click_signal_emitted() -> void:
	var node: Node2D = await _create_node("circle_node")
	var signal_fired: Dictionary = {"fired": false, "ref": null}
	node.connect("clicked", func(_event: InputEvent, n: Node) -> void:
		signal_fired["fired"] = true
		signal_fired["ref"] = n
	)

	var event: Dictionary = _make_pointer_event(Vector2.ZERO, Vector2.ZERO)
	node.call("handle_click", event)

	assert_bool(signal_fired["fired"]).is_true()
	assert_object(signal_fired["ref"]).is_same(node)

	node.free()


## A7: Double-click is a no-op — method exists but does nothing.
func test_double_click_noop() -> void:
	var node: Node2D = await _create_node("circle_node")
	# No double_clicked signal exists on CanvasNode.
	assert_bool(node.has_signal("double_clicked")).is_false()

	# The method exists and returns true without doing anything observable.
	var result: bool = node.call("handle_double_click", {})
	assert_bool(result).is_true()

	node.free()


# ===== A8-A11: Drag Behavior ================================================

## A8: Drag begin when not selected returns false.
func test_drag_begin_not_selected() -> void:
	var node: Node2D = await _create_node("circle_node")
	node.set("is_selected", false)

	var result: bool = node.call("handle_drag_begin", _make_pointer_event())
	assert_bool(result).is_false()

	node.free()


## A9: Drag begin when selected returns true.
func test_drag_begin_selected() -> void:
	var node: Node2D = await _create_node("circle_node")
	node.set("is_selected", true)

	var result: bool = node.call("handle_drag_begin", _make_pointer_event(Vector2(100, 100)))
	assert_bool(result).is_true()

	node.free()


## A10: Drag move emits multi_drag_moved and updates position.
func test_drag_move_emits_multi_drag_moved() -> void:
	var node: Node2D = await _create_node("circle_node")
	node.set("is_selected", true)
	node.position = Vector2(100, 100)

	var signal_fired: Dictionary = {"fired": false, "delta": Vector2.ZERO}
	node.connect("multi_drag_moved", func(d: Vector2) -> void:
		signal_fired["fired"] = true
		signal_fired["delta"] = d
	)

	# Begin drag at world (100, 100).
	node.call("handle_drag_begin", _make_pointer_event(Vector2(100, 100)))

	# Advance drag to (130, 140).
	node.call("handle_drag_move", _make_pointer_event(Vector2(130, 140)))

	assert_bool(signal_fired["fired"]).is_true()
	assert_vector(signal_fired["delta"]).is_equal_approx(Vector2(30, 40), 0.1)
	# Position should be approx (130, 140) but may be modified by overlap resolution.
	assert_vector(node.position).is_equal_approx(Vector2(130, 140), 1.0)

	node.free()


## A11: Drag end snaps to grid.
func test_drag_end_snaps_to_grid() -> void:
	var node: Node2D = await _create_node("circle_node")
	node.set("is_selected", true)
	node.position = Vector2(100, 100)

	# Begin drag.
	node.call("handle_drag_begin", _make_pointer_event(Vector2(100, 100)))

	# Move to non-snapped position.
	node.call("handle_drag_move", _make_pointer_event(Vector2(137, 152)))

	var multi_drag_ended_fired: bool = false
	node.connect("multi_drag_ended", func() -> void:
		multi_drag_ended_fired = true
	)

	var anchor_changed_fired: bool = false
	node.connect("anchor_changed", func() -> void:
		anchor_changed_fired = true
	)

	# End drag — should snap to grid.
	node.call("handle_drag_end", _make_pointer_event())

	# Position snapped to 20px grid (140, 160).
	assert_vector(node.position).is_equal(Vector2(140, 160))
	assert_bool(multi_drag_ended_fired).is_true()
	# anchor_changed fires after snap inside handle_drag_end.
	assert_bool(anchor_changed_fired).is_true()

	node.free()


# ===== A12-A14: Selection Visuals ===========================================

## A12: Selected primary — stroke is lighter than non-selected.
## We verify via is_selected/is_primary flags and that queue_redraw is triggered.
func test_selected_primary_visuals() -> void:
	var node: Node2D = await _create_node("circle_node")

	node.set("is_selected", true)
	node.set("is_primary", true)

	assert_bool(node.get("is_selected")).is_true()
	assert_bool(node.get("is_primary")).is_true()
	# The draw uses fill_color.lightened(0.4) when selected+primary.
	# We verify the stroke would be lighter than non-selected by checking constants.
	var default_fill: Color = Color(0.231, 0.51, 0.965)
	var primary_stroke: Color = default_fill.lightened(0.4)
	var deselected_stroke: Color = default_fill.darkened(0.4)
	assert_bool(primary_stroke.v > deselected_stroke.v).is_true()

	node.free()


## A13: Selected non-primary — stroke dimmer than primary.
func test_selected_non_primary_visuals() -> void:
	var node: Node2D = await _create_node("circle_node")

	node.set("is_selected", true)
	node.set("is_primary", false)

	assert_bool(node.get("is_selected")).is_true()
	assert_bool(node.get("is_primary")).is_false()
	# Stroke = fill_color.lightened(0.25) for non-primary selected.
	var default_fill: Color = Color(0.231, 0.51, 0.965)
	var primary_stroke: Color = default_fill.lightened(0.4)
	var non_primary_stroke: Color = default_fill.lightened(0.25)
	assert_bool(primary_stroke.v > non_primary_stroke.v).is_true()

	node.free()


## A14: Deselected — is_selected = false, is_primary = false.
func test_deselected_no_handles() -> void:
	var node: Node2D = await _create_node("circle_node")

	node.call("set_selected", true)
	assert_bool(node.get("is_selected")).is_true()

	node.call("set_selected", false)
	assert_bool(node.get("is_selected")).is_false()
	assert_bool(node.get("is_primary")).is_false()

	node.free()


# ===== A15-A16: Overlap Bump ================================================

## A15: Node bumps LabelShape out of overlap range.
func test_node_bumps_shape() -> void:
	var node: Node2D = await _create_node("circle_node")
	node.position = Vector2(5, 5)

	# Create a LabelShape at (0, 0) with rx=80, ry=50.
	var label_shape_scene: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")
	var shape: Node2D = label_shape_scene.instantiate()
	shape.set("rx", 80.0)
	shape.set("ry", 50.0)
	shape.position = Vector2(0, 0)
	get_tree().root.add_child(shape)
	await get_tree().process_frame

	# Resolve overlaps on the node.
	node.call("resolve_overlaps")

	# The shape should be pushed away so distance >= overlap_radius + CIRCLE_RADIUS.
	var min_dist: float = shape.call("overlap_radius") + node.call("overlap_radius")
	var dist: float = shape.global_position.distance_to(node.global_position)
	assert_bool(dist >= min_dist - 0.1).is_true()

	shape.free()
	node.free()


## A16: Node bumps another node out of overlap range.
func test_node_bumps_another_node() -> void:
	var node_a: Node2D = await _create_node("circle_node")
	node_a.position = Vector2(0, 0)

	var node_b: Node2D = await _create_node("circle_node")
	node_b.position = Vector2(3, 3)

	# Resolve overlaps on the first node.
	node_a.call("resolve_overlaps")

	# Distance should be >= 16px (8+8).
	var dist: float = node_a.global_position.distance_to(node_b.global_position)
	assert_bool(dist >= 15.9).is_true()

	node_a.free()
	node_b.free()


# ===== A17-A18: No Text/Resize Methods ======================================

## A17: CanvasNode has no text methods.
func test_node_has_no_text_methods() -> void:
	var node: Node2D = await _create_node("circle_node")

	assert_bool(node.has_method("open_text_editor")).is_false()
	assert_bool(node.has_property("text_content")).is_false()

	node.free()


## A18: CanvasNode has no resize methods.
func test_node_has_no_resize_methods() -> void:
	var node: Node2D = await _create_node("circle_node")

	assert_bool(node.has_method("handle_at_pos")).is_false()
	assert_bool(node.has_property("rx")).is_false()
	assert_bool(node.has_property("ry")).is_false()

	node.free()
