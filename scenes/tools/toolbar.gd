class_name Toolbar
extends Control

## Bottom-center toolbar with tool buttons.
## Emits signals to Main.gd when tool modes change.
## Uses toggle-mode buttons for one-click tool activation.
## Each tool button (Shape, Node) also opens a popup for sub-mode selection.


signal shape_sub_mode_changed(sub_mode: String)
signal select_mode_toggled(active: bool)
signal node_sub_mode_changed(sub_mode: String)

enum ToolMode { NONE, SELECT, SHAPE, NODE }

## Shape sub-mode tracking and labels.
const SHAPE_SUB_MODES: Array[String] = ["oval", "circle"]
const SHAPE_LABELS: Dictionary = {"oval": "Oval", "circle": "Circle"}

## Node sub-mode tracking and labels.
const NODE_SUB_MODES: Array[String] = ["circle_node", "triangle_node"]
const NODE_LABELS: Dictionary = {"circle_node": "Circle Node", "triangle_node": "Triangle Node"}

@export var tool_context: ToolContext = preload("uid://cgmt207kt08s4")

## Currently selected shape sub-mode ("oval" or "circle").
var current_shape_sub_mode: String = "oval"

## Currently selected node sub-mode ("circle_node" or "triangle_node").
var current_node_sub_mode: String = "circle_node"

## Whether select mode is currently active.
var select_mode_active: bool = true

## Tracks the active tool mode to enforce mutual exclusivity.
var _active_tool: ToolMode = ToolMode.SELECT

@onready var panel: Panel = $Panel
@onready var select_button: Button = %SelectButton
@onready var shape_button: Button = %ShapeButton
@onready var shape_popup: PopupMenu = %ShapePopup
@onready var node_button: Button = %NodeButton
@onready var node_popup: PopupMenu = %NodePopup



func _ready() -> void:
	GameState.toolbar = self
	_update_shape_button_label()
	_update_node_button_label()
	# Start in Select mode (pressed).
	select_button.button_pressed = true
	_active_tool = ToolMode.SELECT
	
	select_button.toggled.connect(_on_select_button_toggled)
	shape_button.toggled.connect(_on_shape_button_toggled)
	shape_popup.id_pressed.connect(_on_shape_popup_item_selected)
	node_button.toggled.connect(_on_node_button_toggled)
	node_popup.id_pressed.connect(_on_node_popup_item_selected)


## One-click shape tool activation.
## Pressing the shape button toggles it on (and deactivates other tools)
## and opens the variant popup immediately.
func _on_shape_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# Deactivate other tools
		_deactivate_other_tools(ToolMode.SHAPE)
		_active_tool = ToolMode.SHAPE
		select_button.button_pressed = false
		select_mode_active = false
		select_mode_toggled.emit(false)
		shape_sub_mode_changed.emit(current_shape_sub_mode)
		# Open the popup so the user can change variant if desired.
		shape_popup.popup(Rect2i(shape_button.global_position, shape_button.size))
	else:
		# Toggled off: go back to select mode.
		_activate_select_mode()


## Handles selection from the shape popup menu.
## Updates the sub-mode label and keeps the tool active.
func _on_shape_popup_item_selected(id: int) -> void:
	if id >= 0 and id < SHAPE_SUB_MODES.size():
		current_shape_sub_mode = SHAPE_SUB_MODES[id]
		_update_shape_button_label()
		shape_sub_mode_changed.emit(current_shape_sub_mode)
		# Ensure the shape tool stays active.
		if not shape_button.button_pressed:
			shape_button.button_pressed = true
			_on_shape_button_toggled(true)


## One-click node tool activation.
## Pressing the node button toggles it on (and deactivates other tools)
## and opens the variant popup immediately.
func _on_node_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		tool_context.current_tool_type = ToolContext.ToolTypes.CIRCLE_NODE
		# Deactivate other tools
		_deactivate_other_tools(ToolMode.NODE)
		_active_tool = ToolMode.NODE
		select_button.button_pressed = false
		select_mode_active = false
		select_mode_toggled.emit(false)
		node_sub_mode_changed.emit(current_node_sub_mode)
		# Open the popup so the user can change variant if desired.
		node_popup.popup(Rect2i(node_button.global_position, node_button.size))
	else:
		# Toggled off: go back to select mode.
		_activate_select_mode()


## Handles selection from the node popup menu.
## Updates the sub-mode label and keeps the tool active.
func _on_node_popup_item_selected(id: int) -> void:
	if id >= 0 and id < NODE_SUB_MODES.size():
		current_node_sub_mode = NODE_SUB_MODES[id]
		_update_node_button_label()
		node_sub_mode_changed.emit(current_node_sub_mode)
		# Ensure the node tool stays active.
		if not node_button.button_pressed:
			node_button.button_pressed = true
			_on_node_button_toggled(true)


## Forward the button toggle state to Main via signal.
func _on_select_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_select_mode()
	else:
		# If select is manually un-toggled (e.g. another tool deactivated it first),
		# only update state if it was previously in SELECT.
		if _active_tool == ToolMode.SELECT:
			_active_tool = ToolMode.NONE
		select_mode_active = false
		select_mode_toggled.emit(false)


## Deactivates other tool buttons when one tool is activated.
## Called only from shape/node button handlers, so SELECT check is a safety guard.
func _deactivate_other_tools(active: ToolMode) -> void:
	if active != ToolMode.SELECT:
		if shape_button.button_pressed and active != ToolMode.SHAPE:
			shape_button.button_pressed = false
		if node_button.button_pressed and active != ToolMode.NODE:
			node_button.button_pressed = false


## Activates select mode and deactivates all other tools.
func _activate_select_mode() -> void:
	_active_tool = ToolMode.SELECT
	select_mode_active = true
	select_button.button_pressed = true
	shape_button.button_pressed = false
	node_button.button_pressed = false
	select_mode_toggled.emit(true)


## Updates the shape button text to show current sub-mode with dropdown indicator.
func _update_shape_button_label() -> void:
	shape_button.text = SHAPE_LABELS[current_shape_sub_mode] + " ▾"


## Updates the node button text to show current sub-mode with dropdown indicator.
func _update_node_button_label() -> void:
	node_button.text = NODE_LABELS[current_node_sub_mode] + " ▾"
