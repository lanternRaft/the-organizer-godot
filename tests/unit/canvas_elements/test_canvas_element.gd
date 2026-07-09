# GdUnit generated TestSuite
class_name CanvasElementTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")

# TestSuite generated from
const __source: String = "res://scenes/canvas_elements/canvas_element.gd"

const GRID_SIZE: float = 20.0

# ----- Helpers ---------------------------------------------------------------


## Instantiates a CanvasElement, adds to tree, and returns it.
func _create_element() -> CanvasElement:
	var element: CanvasElement = CanvasElement.new()
	get_tree().root.add_child(element)
	await get_tree().process_frame
	return element


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


# ===== CanvasElement can be instantiated as standalone ======================


func test_canvas_element_instantiate() -> void:
	var element: CanvasElement = CanvasElement.new()
	assert_bool(element is CanvasElement).is_true()
	assert_bool(element is Node2D).is_true()
	element.free()


# ===== CanvasElement joins clickable and clickable_element groups on _ready ==


func test_canvas_element_group_membership() -> void:
	var element: CanvasElement = await _create_element()
	assert_bool(element.is_in_group("clickable")).is_true()
	assert_bool(element.is_in_group("clickable_element")).is_true()
	element.free()


# ===== set_selected sets is_selected true and triggers redraw ===============


func test_set_selected_sets_flag() -> void:
	var element: CanvasElement = await _create_element()
	assert_bool(element.is_selected).is_false()

	element.set_selected(true)
	assert_bool(element.is_selected).is_true()

	# queue_redraw was called — we can't directly observe redraw, but
	# we can verify no errors occurred and the flag is correctly set.
	element.free()


# ===== set_selected false clears is_primary flag ============================


func test_set_selected_false_clears_primary() -> void:
	var element: CanvasElement = await _create_element()

	element.set_selected(true)
	element.is_primary = true
	assert_bool(element.is_primary).is_true()

	element.set_selected(false)
	assert_bool(element.is_selected).is_false()
	assert_bool(element.is_primary).is_false()

	element.free()


# ===== handle_drag_begin returns false when not selected ====================


func test_drag_begin_requires_selected() -> void:
	var element: CanvasElement = await _create_element()
	element.is_selected = false

	var result: bool = element.handle_drag_begin(_make_pointer_event())
	assert_bool(result).is_false()

	element.free()


# ===== handle_drag_move updates element position by delta ===================


func test_drag_move_updates_position() -> void:
	var element: CanvasElement = await _create_element()
	element.is_selected = true
	element.position = Vector2(100, 100)

	# Begin drag at (100, 100).
	element.handle_drag_begin(_make_pointer_event(Vector2(100, 100)))

	# Drag to (130, 140).
	element.handle_drag_move(_make_pointer_event(Vector2(130, 140)))

	assert_vector(element.position).is_equal_approx(Vector2(130, 140), Vector2(1.0, 1.0))

	element.free()


# ===== handle_drag_move emits multi_drag_moved with incremental delta =======


func test_drag_move_emits_incremental() -> void:
	var element: CanvasElement = await _create_element()
	element.is_selected = true
	element.position = Vector2(100, 100)

	var signal_fired: Dictionary = {"fired": false, "delta": Vector2.ZERO}
	element.multi_drag_moved.connect(
		func(d: Vector2) -> void:
			signal_fired["fired"] = true
			signal_fired["delta"] = d
	)

	# Begin drag at (100, 100).
	element.handle_drag_begin(_make_pointer_event(Vector2(100, 100)))

	# Advance drag to (130, 140).
	element.handle_drag_move(_make_pointer_event(Vector2(130, 140)))

	assert_bool(signal_fired["fired"]).is_true()
	assert_vector(signal_fired["delta"]).is_equal_approx(Vector2(30, 40), Vector2(0.1, 0.1))

	element.free()


# ===== handle_drag_end snaps position to 20px grid ==========================


func test_drag_end_snaps_to_grid() -> void:
	var element: CanvasElement = await _create_element()
	element.is_selected = true
	element.position = Vector2(100, 100)

	# Begin drag.
	element.handle_drag_begin(_make_pointer_event(Vector2(100, 100)))

	# Move to non-snapped position.
	element.handle_drag_move(_make_pointer_event(Vector2(137, 152)))

	# End drag — should snap to 20px grid.
	element.handle_drag_end(_make_pointer_event())

	# Position snapped to 20px grid (140, 160).
	assert_vector(element.position).is_equal(Vector2(140, 160))

	element.free()


# ===== handle_drag_end emits anchor_changed and multi_drag_ended ============


func test_drag_end_emits_signals() -> void:
	var element: CanvasElement = await _create_element()
	element.is_selected = true
	element.position = Vector2(100, 100)

	var anchor_fired: bool = false
	var multi_fired: bool = false

	element.anchor_changed.connect(func() -> void: anchor_fired = true)
	element.multi_drag_ended.connect(func() -> void: multi_fired = true)

	# Begin and move drag so there's a body drag to end.
	element.handle_drag_begin(_make_pointer_event(Vector2(100, 100)))
	element.handle_drag_move(_make_pointer_event(Vector2(150, 150)))
	element.handle_drag_end(_make_pointer_event())

	assert_bool(anchor_fired).is_true()
	assert_bool(multi_fired).is_true()

	element.free()


# ===== get_anchor_positions returns empty array on base class ===============


func test_get_anchor_positions_default_empty() -> void:
	var element: CanvasElement = CanvasElement.new()
	var anchors: Array[Dictionary] = element.get_anchor_positions()
	assert_int(anchors.size()).is_equal(0)
	element.free()


# ===== Default handle_click sets drag_mode body and emits clicked ===========


func test_handle_click_default_behavior() -> void:
	var element: CanvasElement = await _create_element()

	var signal_fired: Dictionary = {"fired": false, "ref": null}
	element.clicked.connect(
		func(_event: InputEvent, el: Node) -> void:
			signal_fired["fired"] = true
			signal_fired["ref"] = el
	)

	var event: Dictionary = _make_pointer_event(Vector2.ZERO, Vector2.ZERO)
	var result: bool = element.handle_click(event)

	assert_bool(result).is_true()
	assert_bool(signal_fired["fired"]).is_true()
	assert_object(signal_fired["ref"]).is_same(element)
	# Drag mode should be set to "body".
	assert_str(element._drag_mode).is_equal("body")

	element.free()


# ===== Default handle_double_click returns true as no-op ====================


func test_handle_double_click_noop() -> void:
	var element: CanvasElement = await _create_element()

	# The method exists and returns true without doing anything observable.
	var result: bool = element.handle_double_click({})
	assert_bool(result).is_true()

	element.free()


# ===== supports_text_editing returns false by default =======================


func test_supports_text_editing_default_false() -> void:
	var element: CanvasElement = CanvasElement.new()
	assert_bool(element.supports_text_editing()).is_false()
	element.free()


# ===== shows_in_legend returns false by default =============================


func test_shows_in_legend_default_false() -> void:
	var element: CanvasElement = CanvasElement.new()
	assert_bool(element.shows_in_legend()).is_false()
	element.free()
