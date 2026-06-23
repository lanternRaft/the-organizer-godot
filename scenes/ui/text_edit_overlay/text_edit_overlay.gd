class_name TextEditOverlay
extends Control

## Screen-space text editing overlay for LabelShape elements.
## Opens a TextEdit widget centered over a shape, with Enter to commit
## and Escape to cancel. Emits signals for persistence triggers.

## Emitted when text is committed (Enter without Shift).
signal text_committed(shape: Node, text: String)

## Emitted when editing is cancelled (Escape or focus loss).
signal text_cancelled(shape: Node)

## Reference to the shape being edited, or null if the overlay is closed.
var editing_shape: LabelShape = null

## Whether the overlay is currently open.
var is_open: bool = false

@onready var panel: Panel = $Panel
@onready var text_edit: TextEdit = $Panel/MarginContainer/TextEdit


func _ready() -> void:
	visible = false
	text_edit.text_changed.connect(_on_text_changed)
	text_edit.focus_exited.connect(_on_text_edit_focus_exited)


## Opens the overlay positioned over the given shape.
## @param shape:        The LabelShape being edited.
## @param screen_rect:  A Rect2 defining the screen-space position and size of the overlay.
func open(shape: LabelShape, screen_rect: Rect2) -> void:
	editing_shape = shape
	is_open = true

	# Position and size the overlay.
	position = screen_rect.position
	size = screen_rect.size

	# Pre-populate with existing text.
	text_edit.text = shape.text_content
	text_edit.clear()

	# Make visible and focus.
	visible = true
	text_edit.grab_focus.call_deferred()


## Closes the overlay without committing changes.
func cancel() -> void:
	if editing_shape != null:
		text_cancelled.emit(editing_shape)
	_close()


## Closes the overlay with the current text committed.
func commit() -> void:
	if editing_shape != null:
		text_committed.emit(editing_shape, text_edit.text)
	_close()


func _close() -> void:
	is_open = false
	visible = false
	editing_shape = null
	text_edit.text = ""


## Handles keyboard input within the TextEdit.
func _input(event: InputEvent) -> void:
	if not is_open or not visible:
		return

	if event is InputEventKey:
		var ke: InputEventKey = event
		if ke.pressed and not ke.echo:
			match ke.keycode:
				KEY_ENTER:
					# Enter without Shift commits.
					if not ke.shift_pressed:
						commit()
						get_viewport().set_input_as_handled()
				KEY_ESCAPE:
					cancel()
					get_viewport().set_input_as_handled()


## Called when the TextEdit loses focus (canvas click, toolbar click, etc.).
## Commits the current text (even empty) and closes the overlay.
## Edge cases:
## - Escape fires before focus_exited; cancel() sets is_open=false, making this a no-op.
## - Enter fires commit() before focus_exited; _close() clears editing_shape, making commit() a no-op.
func _on_text_edit_focus_exited() -> void:
	if is_open:
		commit()


## Tracks text changes to update the shape's display in real-time.
func _on_text_changed() -> void:
	if is_open and editing_shape != null:
		editing_shape.text_content = text_edit.text
