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


## Activates a tool mode, deactivating all others.
## Opens the tool's popup for sub-mode selection.
func _activate_tool(
	mode: ToolMode,
	button: Button,
	popup: PopupMenu,
	sub_mode_signal: Signal
) -> void:
	_deactivate_other_tools(mode)
	_active_tool = mode
	select_button.button_pressed = false
	select_mode_active = false
	select_mode_toggled.emit(false)
	sub_mode_signal.emit()
	popup.popup(Rect2i(button.global_position, button.size))


## Handles popup item selection for a tool.
## Updates the sub-mode, label, and keeps the tool active.
func _on_popup_item_selected(
	id: int,
	sub_modes: Array[String],
	set_sub_mode: Callable,
	label_update: Callable,
	sub_mode_signal: Signal,
	button: Button,
	toggle_handler: Callable
) -> void:
	if id >= 0 and id < sub_modes.size():
		set_sub_mode.call(sub_modes[id])
		label_update.call()
		sub_mode_signal.emit(sub_modes[id])
		# Ensure the tool button stays active.
		if not button.button_pressed:
			button.button_pressed = true
			toggle_handler.call(true)


## One-click shape tool activation.
## Pressing the shape button toggles it on (and deactivates other tools)
## and opens the variant popup immediately.
func _on_shape_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_tool(
			ToolMode.SHAPE,
			shape_button,
			shape_popup,
			shape_sub_mode_changed.bind(current_shape_sub_mode)
		)
	else:
		_activate_select_mode()


## Handles selection from the shape popup menu.
## Updates the sub-mode label and keeps the tool active.
func _on_shape_popup_item_selected(id: int) -> void:
	_on_popup_item_selected(
		id,
		SHAPE_SUB_MODES,
		func(v: String): current_shape_sub_mode = v,
		_update_shape_button_label,
		shape_sub_mode_changed,
		shape_button,
		_on_shape_button_toggled
	)


## One-click node tool activation.
## Pressing the node button toggles it on (and deactivates other tools)
## and opens the variant popup immediately.
func _on_node_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_tool(
			ToolMode.NODE,
			node_button,
			node_popup,
			node_sub_mode_changed.bind(current_node_sub_mode)
		)
	else:
		_activate_select_mode()


## Handles selection from the node popup menu.
## Updates the sub-mode label and keeps the tool active.
func _on_node_popup_item_selected(id: int) -> void:
	_on_popup_item_selected(
		id,
		NODE_SUB_MODES,
		func(v: String): current_node_sub_mode = v,
		_update_node_button_label,
		node_sub_mode_changed,
		node_button,
		_on_node_button_toggled
	)


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