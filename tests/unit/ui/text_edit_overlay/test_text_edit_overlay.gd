# GdUnit generated TestSuite
class_name TextEditOverlayTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/ui/text_edit_overlay/text_edit_overlay.gd'
const __scene: PackedScene = preload("res://scenes/ui/text_edit_overlay/text_edit_overlay.tscn")
const LABEL_SHAPE_SCENE: PackedScene = preload("res://scenes/tools/label_shape/label_shape.tscn")

## Helper: creates a TextEditOverlay, adds it to the tree, and returns it.
func _create_overlay() -> Control:
	var overlay: Control = __scene.instantiate()
	get_tree().root.add_child(overlay)
	await get_tree().process_frame  # Wait one frame for _ready()
	return overlay


## Helper: creates a LabelShape for testing.
func _create_shape() -> Node:
	var shape: Node = LABEL_SHAPE_SCENE.instantiate()
	get_tree().root.add_child(shape)
	await get_tree().process_frame
	return shape


## Helper: opens the overlay with a shape and a given initial text.
func _open_overlay(overlay: Control, shape: Node, initial_text: String) -> void:
	if shape.has_method(&"set_text_content"):
		shape.call(&"set_text_content", initial_text)
	overlay.call(&"open", shape, Rect2(100, 100, 200, 150))
	await get_tree().process_frame


## Helper: gets the TextEdit node from the overlay.
func _get_text_edit(overlay: Control) -> TextEdit:
	return overlay.get_node("Panel/MarginContainer/TextEdit") as TextEdit


## Test 5: focus_exited on a TextEdit with text emits text_committed.
func test_focus_exited_commits_text() -> void:
	var overlay: Control = await _create_overlay()
	var shape: Node = await _create_shape()
	await _open_overlay(overlay, shape, "Hello")

	# Watch for the signal using a dictionary so lambda mutation works.
	var signal_result: Dictionary = {
		"fired": false,
		"text": ""
	}
	overlay.connect("text_committed", func(_s: Node, text: String) -> void:
		signal_result["fired"] = true
		signal_result["text"] = text
	)

	# Release focus on the TextEdit after setting text (open() clears it).
	var text_edit: TextEdit = _get_text_edit(overlay)
	text_edit.text = "Hello"
	text_edit.grab_focus()
	await get_tree().process_frame
	text_edit.release_focus()
	await get_tree().process_frame

	assert_bool(signal_result["fired"]).is_true()
	assert_str(signal_result["text"]).is_equal("Hello")

	overlay.free()
	shape.free()


## Test 6: focus_exited on a TextEdit with empty text still commits (blank is valid).
func test_focus_exited_commits_empty_text() -> void:
	var overlay: Control = await _create_overlay()
	var shape: Node = await _create_shape()
	await _open_overlay(overlay, shape, "")

	# Watch for the signal using a dictionary so lambda mutation works.
	var signal_result: Dictionary = {
		"fired": false,
		"text": "not_fired"
	}
	overlay.connect("text_committed", func(_s: Node, text: String) -> void:
		signal_result["fired"] = true
		signal_result["text"] = text
	)

	# Release focus on the TextEdit after setting text (open() clears it).
	var text_edit: TextEdit = _get_text_edit(overlay)
	text_edit.text = ""
	text_edit.grab_focus()
	await get_tree().process_frame
	text_edit.release_focus()
	await get_tree().process_frame

	assert_bool(signal_result["fired"]).is_true()
	assert_str(signal_result["text"]).is_equal("")

	overlay.free()
	shape.free()


## Test 7: pressing Escape still cancels (text_cancelled, not text_committed)
## even though focus_exited is also connected.
func test_escape_still_cancels_on_focus_exited() -> void:
	var overlay: Control = await _create_overlay()
	var shape: Node = await _create_shape()
	await _open_overlay(overlay, shape, "Hello")

	var signal_result: Dictionary = {
		"committed": false,
		"cancelled": false
	}
	overlay.connect("text_committed", func(_s: Node, _text: String) -> void:
		signal_result["committed"] = true
	)
	overlay.connect("text_cancelled", func(_s: Node) -> void:
		signal_result["cancelled"] = true
	)

	# Focus the TextEdit, then press Escape.
	var text_edit: TextEdit = _get_text_edit(overlay)
	text_edit.grab_focus()
	await get_tree().process_frame

	# Simulate Escape key press.
	var escape_event: InputEventKey = InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	get_viewport().push_input.call_deferred(escape_event)
	await get_tree().process_frame

	assert_bool(signal_result["cancelled"]).is_true()
	assert_bool(signal_result["committed"]).is_false()

	overlay.free()
	shape.free()


## Helper: creates a mock Camera2D at the given position and zoom,
## and makes it the active camera for the viewport.
func _create_mock_camera(position: Vector2, zoom: float) -> Camera2D:
	var camera: Camera2D = Camera2D.new()
	camera.position = position
	camera.zoom = Vector2(zoom, zoom)
	get_tree().root.add_child(camera)
	camera.make_current()
	await get_tree().process_frame
	return camera


## Test 8: reposition recalculates position when overlay is open.
func test_reposition_recalculates_when_open() -> void:
	var overlay: Control = await _create_overlay()
	var shape: Node = await _create_shape()
	shape.set(&"position", Vector2(400.0, 300.0))
	await _open_overlay(overlay, shape, "Hello")

	var _initial_pos: Vector2 = overlay.position
	var camera: Camera2D = await _create_mock_camera(Vector2.ZERO, 1.0)

	# Shape at (400, 300), camera at (0, 0), zoom=1.0.
	var pos_before: Vector2 = overlay.position
	var size_before: Vector2 = overlay.size

	# Simulate a pan: move camera right by 100px.
	camera.position = Vector2(100.0, 0.0)
	overlay.call(&"reposition", camera, 1.0)

	var pos_after: Vector2 = overlay.position
	# Position should change when camera pans (it shouldn't stay the same).
	assert_bool(not pos_after.is_equal_approx(pos_before)).is_true()
	# Size is recalculated from shape bounds: width = max(160, 80*2*1.0) = 160, height = max(80, 50*2*1.0) = 100
	assert_float(overlay.size.x).is_equal(160.0)
	assert_float(overlay.size.y).is_equal(100.0)
	# Size should differ from the initial open() rect (200, 150).
	assert_bool(not overlay.size.is_equal_approx(size_before)).is_true()

	camera.free()
	overlay.free()
	shape.free()


## Test 9: reposition is a no-op when overlay is closed.
func test_reposition_noop_when_closed() -> void:
	var overlay: Control = await _create_overlay()
	var camera: Camera2D = await _create_mock_camera(Vector2.ZERO, 1.0)

	overlay.call(&"reposition", camera, 1.0)
	# No error was thrown. This test passes by not crashing.
	assert_bool(true).is_true()

	camera.free()
	overlay.free()


## Test 10: reposition is a no-op when editing_shape is null.
func test_reposition_noop_when_null_shape() -> void:
	var overlay: Control = await _create_overlay()
	var camera: Camera2D = await _create_mock_camera(Vector2.ZERO, 1.0)

	# Set is_open to true but editing_shape stays null.
	overlay.set(&"is_open", true)
	overlay.call(&"reposition", camera, 1.0)
	# No error. This test passes by not crashing.
	assert_bool(true).is_true()

	camera.free()
	overlay.free()


## Test 11: reposition updates size on zoom change.
func test_reposition_updates_on_zoom_change() -> void:
	var overlay: Control = await _create_overlay()
	var shape: Node = await _create_shape()
	shape.set(&"position", Vector2(400.0, 300.0))
	await _open_overlay(overlay, shape, "Hello")

	var camera: Camera2D = await _create_mock_camera(Vector2.ZERO, 2.0)

	overlay.call(&"reposition", camera, 2.0)

	# With zoom=2.0, overlay size should scale:
	# width = max(160, shape.rx * 2.0 * 2.0) = max(160, 80 * 4) = max(160, 320) = 320
	# height = max(80, shape.ry * 2.0 * 2.0) = max(80, 50 * 4) = max(80, 200) = 200
	assert_float(overlay.size.x).is_equal(320.0)
	assert_float(overlay.size.y).is_equal(200.0)

	camera.free()
	overlay.free()
	shape.free()