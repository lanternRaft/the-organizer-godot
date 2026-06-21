extends Node

## Root controller of the app. Owns the canvas, camera, UI, and input dispatch.

@onready var element_layer: Node2D = %ElementLayer
@onready var info_bar: Label = %InfoBar
@onready var canvas: Node2D = %Canvas
@onready var oval_button: Button = $UI/Toolbar/OvalButton

## Preload LabelShape so we can instantiate on click.
const LabelShape: PackedScene = preload("res://scenes/label_shape/LabelShape.tscn")

## Whether oval-placement mode is currently active.
var oval_mode_active: bool = false

## Reference to the last placed shape (useful for future undo / selection).
var last_placed: Node2D = null


func _ready() -> void:
	## Clip canvas rendering to the viewport bounds.
	canvas.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	update_info_bar()


func _unhandled_input(event: InputEvent) -> void:
	## Handle Escape to deactivate oval mode.
	if event.is_action_pressed("ui_cancel") and oval_mode_active:
		deactivate_oval_mode()
		get_viewport().set_input_as_handled()
		return

	## Place oval on left-click when in oval mode.
	if oval_mode_active and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			place_oval(element_layer.get_global_mouse_position())


## Creates a new oval at the given world position and parents it to ElementLayer.
func place_oval(pos: Vector2) -> void:
	var shape: Node2D = LabelShape.instantiate()
	shape.position = pos
	element_layer.add_child(shape)
	last_placed = shape


## Activates oval-placement mode.
func activate_oval_mode() -> void:
	oval_mode_active = true
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	oval_button.button_pressed = true
	update_info_bar()


## Deactivates oval-placement mode and returns to neutral state.
func deactivate_oval_mode() -> void:
	oval_mode_active = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	oval_button.button_pressed = false
	update_info_bar()


## Toggles oval mode on/off. Connected to Toolbar's signal.
func _on_oval_mode_toggled(active: bool) -> void:
	if active:
		activate_oval_mode()
	else:
		deactivate_oval_mode()


## Updates the info bar hint text based on current state.
func update_info_bar() -> void:
	if oval_mode_active:
		info_bar.text = "Click the canvas to place an oval"
	else:
		info_bar.text = ""
