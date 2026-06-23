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