# GdUnit generated TestSuite
class_name LabelShapeTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/tools/label_shape/label_shape.gd'
const __scene: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")

# ----- Helpers ---------------------------------------------------------------

## Instantiates a LabelShape, adds to tree, and returns it.
func _create_shape(rx: float = 80.0, ry: float = 50.0, pos: Vector2 = Vector2.ZERO) -> LabelShape:
	var shape: LabelShape = __scene.instantiate()
	shape.rx = rx
	shape.ry = ry
	shape.position = pos
	get_tree().root.add_child(shape)
	await get_tree().process_frame
	return shape


## Simulates a pointer event dictionary for drag operations.
func _make_pointer_event(world_pos: Vector2 = Vector2.ZERO, local_pos: Vector2 = Vector2.ZERO) -> Dictionary:
	return {
		"world_pos": world_pos,
		"local_pos": local_pos,
		"pressed": true,
		"dragged": false,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": InputEventMouseButton.new(),
	}


# ===== L1-L4: No Bumping Behavior ===========================================

## L1: handle_drag_move no longer calls resolve_overlaps.
## Position should be exactly drag_start + delta with no push modification.
func test_drag_move_no_resolve_overlaps() -> void:
	var shape: LabelShape = await _create_shape(80.0, 50.0, Vector2(0, 0))
	shape.set_selected(true)

	# Create a second shape that would overlap if bumping existed.
	var other: LabelShape = await _create_shape(80.0, 50.0, Vector2(0, 0))

	# Begin drag at (0, 0).
	shape.call("handle_drag_begin", _make_pointer_event(Vector2(0, 0)))

	# Drag to (50, 0) — this would overlap with the other shape.
	shape.call("handle_drag_move", _make_pointer_event(Vector2(50, 0)))

	# Shape position is exactly (50, 0), no overlap resolution.
	assert_vector(shape.position).is_equal_approx(Vector2(50, 0), Vector2(0.1, 0.1))
	# Other shape remains at (0, 0).
	assert_vector(other.position).is_equal_approx(Vector2(0, 0), Vector2(0.1, 0.1))

	shape.free()
	other.free()


## L2: resolve_overlaps method exists as no-op.
## Calling it on an overlapping shape does not change positions.
func test_resolve_overlaps_noop() -> void:
	var shape_a: LabelShape = await _create_shape(80.0, 50.0, Vector2(0, 0))
	var shape_b: LabelShape = await _create_shape(80.0, 50.0, Vector2(20, 0))

	# They overlap (20px distance < 80+80=160px radii sum).
	var before_pos_b: Vector2 = shape_b.position

	# Call resolve_overlaps — should be a no-op (no error, no position change).
	shape_a.call("resolve_overlaps")

	assert_vector(shape_a.position).is_equal_approx(Vector2(0, 0), Vector2(0.1, 0.1))
	assert_vector(shape_b.position).is_equal_approx(before_pos_b, Vector2(0.1, 0.1))

	shape_a.free()
	shape_b.free()


## L3: overlap_radius method retained for compatibility (hit detection).
func test_overlap_radius_retained() -> void:
	var shape: LabelShape = await _create_shape(80.0, 50.0)

	# overlap_radius returns max(rx, ry) = max(80, 50) = 80.0.
	assert_float(shape.overlap_radius()).is_equal(80.0)

	shape.free()


## L4: Shapes overlapping after drag does not push.
## Two shapes overlapping — dragging one does not push the other.
func test_overlapping_after_drag_no_push() -> void:
	var shape_a: LabelShape = await _create_shape(80.0, 50.0, Vector2(0, 0))
	var shape_b: LabelShape = await _create_shape(80.0, 50.0, Vector2(20, 0))

	shape_a.set_selected(true)

	# Begin drag on shape_a at (0, 0).
	shape_a.call("handle_drag_begin", _make_pointer_event(Vector2(0, 0)))

	# Drag to (50, 0).
	shape_a.call("handle_drag_move", _make_pointer_event(Vector2(50, 0)))

	# shape_a at (50, 0), shape_b still at (20, 0) — they overlap freely.
	assert_vector(shape_a.position).is_equal_approx(Vector2(50, 0), Vector2(0.1, 0.1))
	assert_vector(shape_b.position).is_equal_approx(Vector2(20, 0), Vector2(0.1, 0.1))

	shape_a.free()
	shape_b.free()