# GdUnit generated TestSuite
class_name LabelShapeBaseTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __scene: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")

# Constants matching LabelShape internals.
const DEFAULT_RX: float = 80.0
const DEFAULT_RY: float = 50.0
const HANDLE_SIZE: float = 32.0
const GRID_SIZE: float = 20.0

# ----- Helpers ---------------------------------------------------------------

## Instantiates a LabelShape from scene, adds to tree, and returns it.
func _create_shape() -> LabelShape:
	var shape: LabelShape = __scene.instantiate()
	get_tree().root.add_child(shape)
	await get_tree().process_frame
	return shape


## Simulates a pointer event dictionary.
func _make_pointer_event(world_pos: Vector2 = Vector2.ZERO, local_pos: Vector2 = Vector2.ZERO) -> Dictionary:
	return {
		"world_pos": world_pos,
		"local_pos": local_pos,
		"pressed": true,
		"dragged": false,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": InputEventMouseButton.new(),
	}


# ===== LabelShape inherits from CanvasElement ================================

## LabelShape is an instance of CanvasElement.
func test_label_shape_is_canvas_element() -> void:
	var shape: LabelShape = __scene.instantiate()
	assert_bool(shape is CanvasElement).is_true()
	assert_bool(shape is Node2D).is_true()
	shape.free()


# ===== LabelShape inherits set_selected from base ============================

## LabelShape inherits set_selected from base.
func test_label_shape_inherits_set_selected() -> void:
	var shape: LabelShape = await _create_shape()

	# Initially not selected.
	assert_bool(shape.is_selected).is_false()
	assert_bool(shape.is_primary).is_false()

	# Select the shape.
	shape.set_selected(true)
	assert_bool(shape.is_selected).is_true()

	# Make primary.
	shape.is_primary = true
	assert_bool(shape.is_primary).is_true()

	# Deselect — clears is_primary as well.
	shape.set_selected(false)
	assert_bool(shape.is_selected).is_false()
	assert_bool(shape.is_primary).is_false()

	shape.free()


# ===== LabelShape anchor positions (cardinal) ================================

## LabelShape get_anchor_positions returns 4 cardinal offsets.
func test_label_shape_anchor_positions_cardinal() -> void:
	var shape: LabelShape = await _create_shape()
	var anchors: Array[Dictionary] = shape.get_anchor_positions()
	assert_int(anchors.size()).is_equal(4)

	# Verify labels and offsets match default rx=80, ry=50.
	assert_str(anchors[0]["label"]).is_equal("top")
	assert_vector(anchors[0]["offset"]).is_equal(Vector2(0, -DEFAULT_RY))

	assert_str(anchors[1]["label"]).is_equal("bottom")
	assert_vector(anchors[1]["offset"]).is_equal(Vector2(0, DEFAULT_RY))

	assert_str(anchors[2]["label"]).is_equal("left")
	assert_vector(anchors[2]["offset"]).is_equal(Vector2(-DEFAULT_RX, 0))

	assert_str(anchors[3]["label"]).is_equal("right")
	assert_vector(anchors[3]["offset"]).is_equal(Vector2(DEFAULT_RX, 0))

	shape.free()


## LabelShape anchor positions update after rx/ry change.
func test_label_shape_anchor_positions_follow_resize() -> void:
	var shape: LabelShape = await _create_shape()

	# Change dimensions.
	shape.rx = 120.0
	shape.ry = 70.0

	var anchors: Array[Dictionary] = shape.get_anchor_positions()
	assert_int(anchors.size()).is_equal(4)

	assert_vector(anchors[0]["offset"]).is_equal(Vector2(0, -70.0))
	assert_vector(anchors[1]["offset"]).is_equal(Vector2(0, 70.0))
	assert_vector(anchors[2]["offset"]).is_equal(Vector2(-120.0, 0))
	assert_vector(anchors[3]["offset"]).is_equal(Vector2(120.0, 0))

	shape.free()


# ===== LabelShape handle_click detection =====================================

## LabelShape handle_click detects handle hit vs body hit.
func test_label_shape_handle_click_detects_handle() -> void:
	var shape: LabelShape = await _create_shape()

	# Click on a handle position (bottom-right handle is at (rx - half, ry - half))
	# with rx=80, ry=50, half=16 => br handle rect at (64, 34) with size 32x32.
	var half: float = HANDLE_SIZE / 2.0
	var br_local: Vector2 = Vector2(DEFAULT_RX - half, DEFAULT_RY - half)
	var br_event: Dictionary = _make_pointer_event(Vector2.ZERO, br_local)

	var result: bool = shape.handle_click(br_event)
	assert_bool(result).is_true()
	assert_str(shape._drag_mode).is_equal("handle")
	assert_str(shape._dragging_handle).is_equal("br")

	# Reset drag state manually for second test.
	shape._drag_mode = ""
	shape._dragging_handle = ""

	# Click on body (center of shape).
	var body_local: Vector2 = Vector2(10, 10)
	var body_event: Dictionary = _make_pointer_event(Vector2.ZERO, body_local)

	result = shape.handle_click(body_event)
	assert_bool(result).is_true()
	assert_str(shape._drag_mode).is_equal("body")
	assert_str(shape._dragging_handle).is_equal("")

	shape.free()


# ===== LabelShape virtual property overrides =================================

## LabelShape supports_text_editing returns true.
func test_label_shape_supports_text_editing() -> void:
	var shape: LabelShape = __scene.instantiate()
	assert_bool(shape.supports_text_editing()).is_true()
	shape.free()


## LabelShape shows_in_legend returns true.
func test_label_shape_shows_in_legend() -> void:
	var shape: LabelShape = __scene.instantiate()
	assert_bool(shape.shows_in_legend()).is_true()
	shape.free()


# ===== LabelShape double-click emission ======================================

## LabelShape handle_double_click emits double_clicked signal.
func test_label_shape_double_click_emission() -> void:
	var shape: LabelShape = await _create_shape()

	var signal_fired: Dictionary = {"fired": false, "ref": null}
	shape.double_clicked.connect(func(s: Node) -> void:
		signal_fired["fired"] = true
		signal_fired["ref"] = s
	)

	var result: bool = shape.handle_double_click({})
	assert_bool(result).is_true()
	assert_bool(signal_fired["fired"]).is_true()
	assert_object(signal_fired["ref"]).is_same(shape)

	shape.free()


# ===== LabelShape drag uses inherited base methods ===========================

## LabelShape drag lifecycle uses inherited base methods.
## Body drag is inherited from CanvasElement; handle_drag_begin, move, end
## work correctly for body-drag (single element).
func test_label_shape_drag_uses_inherited_logic() -> void:
	var shape: LabelShape = await _create_shape()
	shape.position = Vector2(100, 100)
	shape.set_selected(true)

	# Body drag: begin at (100, 100).
	var begin_event: Dictionary = _make_pointer_event(Vector2(100, 100), Vector2.ZERO)
	var drag_started: bool = shape.handle_drag_begin(begin_event)
	assert_bool(drag_started).is_true()
	assert_str(shape._drag_mode).is_equal("body")

	# Move to (130, 140).
	var move_event: Dictionary = _make_pointer_event(Vector2(130, 140), Vector2(30, 40))
	shape.handle_drag_move(move_event)

	# Position should be updated to (130, 140).
	assert_vector(shape.position).is_equal_approx(Vector2(130, 140), Vector2(1.0, 1.0))

	# End drag — snaps to grid.
	var end_event: Dictionary = _make_pointer_event(Vector2(130, 140), Vector2(30, 40))
	shape.handle_drag_end(end_event)

	# Position snapped to 20px grid: (140, 140).
	assert_vector(shape.position).is_equal(Vector2(140, 140))
	assert_str(shape._drag_mode).is_equal("")

	shape.free()