extends GdUnitTestSuite
## Tests for the shape resize handle system
## (res://scripts/handles.gd + res://scripts/handle.gd).
##
## Covers:
##   - handle placement at the shape's bounding-box corners
##   - resize keeps the opposite corner fixed, snaps to 10px, clamps to [20, 500]
##   - circle mode keeps both radii equal
##   - line anchors follow the rim as the shape resizes
##   - handles only visible while the shape is selected

const OVAL_SCENE: PackedScene = preload("res://scenes/canvas_elements/oval_label_shape.tscn")

var shape: LabelShape
var handles: Node2D
var runner: GdUnitSceneRunner


func before_test() -> void:
	shape = auto_free(OVAL_SCENE.instantiate())
	runner = scene_runner(shape)
	runner.simulate_frames(2)
	handles = shape.get_node("Handles")


func test_handles_sit_on_shape_corners() -> void:
	var expected: Dictionary = {
		"HandleTopLeft": Vector2(-160, -100),
		"HandleTopRight": Vector2(160, -100),
		"HandleBottomLeft": Vector2(-160, 100),
		"HandleBottomRight": Vector2(160, 100),
	}
	for handle: Node in handles.get_children():
		var expected_pos: Vector2 = expected.get(handle.name, Vector2.INF)
		var h: ResizeHandle = handle as ResizeHandle
		assert_vector(h.position).is_equal(expected_pos)
		assert_vector(h.size).is_equal(Vector2(LabelShape.HANDLE_SIZE, LabelShape.HANDLE_SIZE))


func test_handles_hidden_until_selected() -> void:
	assert_bool(handles.visible).is_equal(false)
	shape.set_selected(true)
	assert_bool(handles.visible).is_equal(true)
	shape.set_selected(false)
	assert_bool(handles.visible).is_equal(false)


func test_oval_uses_centered_collision_shape() -> void:
	var pointer_area: Area2D = shape.get_node("ShapeButton") as Area2D
	assert_object(pointer_area).is_not_null()
	var collision: CollisionShape2D = pointer_area.get_node("CollisionShape2D") as CollisionShape2D
	assert_object(collision).is_not_null()
	assert_bool(collision.shape is ConvexPolygonShape2D).is_equal(true)
	var polygon: ConvexPolygonShape2D = collision.shape as ConvexPolygonShape2D
	var expected: PackedVector2Array = shape.build_collision_polygon()
	assert_int(polygon.points.size()).is_equal(expected.size())
	for i: int in expected.size():
		assert_vector(polygon.points[i]).is_equal(expected[i])


func test_collision_shape_tracks_resize() -> void:
	var pointer_area: Area2D = shape.get_node("ShapeButton") as Area2D
	var collision: CollisionShape2D = pointer_area.get_node("CollisionShape2D") as CollisionShape2D
	shape.rx = 200.0
	shape.ry = 140.0
	runner.simulate_frames(1)
	var polygon: ConvexPolygonShape2D = collision.shape as ConvexPolygonShape2D
	var expected: PackedVector2Array = shape.build_collision_polygon()
	assert_int(polygon.points.size()).is_equal(expected.size())
	for i: int in expected.size():
		assert_vector(polygon.points[i]).is_equal(expected[i])
	assert_vector(pointer_area.position).is_equal(Vector2.ZERO)


func test_resize_bottom_right_keeps_opposite_corner_fixed() -> void:
	handles.call("handle_resize_start", ResizeHandle.BOTTOM_RIGHT)
	handles.call("resize_to_pointer", ResizeHandle.BOTTOM_RIGHT, Vector2(240, 170))
	# Fixed top-left corner stays at (-160, -100); size snaps to 400x270.
	assert_float(shape.rx).is_equal(200.0)
	assert_float(shape.ry).is_equal(135.0)
	assert_vector(shape.position).is_equal(Vector2(40, 35))
	# The grabbed handle ends up on the new corner.
	var br: ResizeHandle = handles.get_node("HandleBottomRight") as ResizeHandle
	assert_vector(br.position).is_equal(Vector2(200, 135))
	# Line anchors follow the new rim.
	var top: Node2D = shape.get_node("Anchors/LineAnchorTop") as Node2D
	var bottom: Node2D = shape.get_node("Anchors/LineAnchorBottom") as Node2D
	var left: Node2D = shape.get_node("Anchors/LineAnchorLeft") as Node2D
	var right: Node2D = shape.get_node("Anchors/LineAnchorRight") as Node2D
	assert_vector(top.position).is_equal(Vector2(0, -135))
	assert_vector(bottom.position).is_equal(Vector2(0, 135))
	assert_vector(left.position).is_equal(Vector2(-200, 0))
	assert_vector(right.position).is_equal(Vector2(200, 0))


func test_resize_top_left_keeps_opposite_corner_fixed() -> void:
	handles.call("handle_resize_start", ResizeHandle.TOP_LEFT)
	handles.call("resize_to_pointer", ResizeHandle.TOP_LEFT, Vector2(-320, -200))
	# Fixed bottom-right corner stays at (160, 100); size snaps to 480x300.
	assert_float(shape.rx).is_equal(240.0)
	assert_float(shape.ry).is_equal(150.0)
	assert_vector(shape.position).is_equal(Vector2(-80, -50))


func test_resize_clamps_at_min_and_max_size() -> void:
	handles.call("handle_resize_start", ResizeHandle.BOTTOM_RIGHT)
	# Pointer too close: a 10px drag snaps up to the 20px minimum.
	handles.call("resize_to_pointer", ResizeHandle.BOTTOM_RIGHT, Vector2(-150, -90))
	assert_float(shape.rx).is_equal(10.0)
	assert_float(shape.ry).is_equal(10.0)
	assert_vector(shape.position).is_equal(Vector2(-150, -90))
	# Pointer too far: clamps down to the 500px maximum.
	handles.call("resize_to_pointer", ResizeHandle.BOTTOM_RIGHT, Vector2(2000, 2000))
	assert_float(shape.rx).is_equal(250.0)
	assert_float(shape.ry).is_equal(250.0)


func test_circle_mode_resizes_both_radii_together() -> void:
	shape.shape_mode = LabelShape.ShapeMode.CIRCLE_MODE
	handles.call("handle_resize_start", ResizeHandle.BOTTOM_RIGHT)
	handles.call("resize_to_pointer", ResizeHandle.BOTTOM_RIGHT, Vector2(80, -10))
	# Width dominates (240 > 90), so both radii become 120.
	assert_float(shape.rx).is_equal(120.0)
	assert_float(shape.ry).is_equal(120.0)
	assert_vector(shape.position).is_equal(Vector2(-40, 20))
