class_name Toolbar
extends PanelContainer

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
@export var shape_tools: Array[Tool]
@export var node_tools: Array[Tool]

## Current shape tool index in shape_tools
var current_shape_tool_idx: int = 0

## Current node tool index in node_tools
var current_node_tool_idx: int = 0

@onready var select_button: Button = %SelectButton
@onready var shape_button: Button = %ShapeButton
@onready var shape_popup: PopupMenu = %ShapePopup
@onready var node_button: Button = %NodeButton
@onready var node_popup: PopupMenu = %NodePopup


func _ready() -> void:
	_setup_tools()
	_connect_signals()
	_refresh()


func _connect_signals() -> void:
	select_button.pressed.connect(_on_select_button_pressed)
	shape_button.pressed.connect(_on_shape_button_pressed)
	shape_popup.id_pressed.connect(_on_shape_popup_item_selected)
	node_button.pressed.connect(_on_node_button_pressed)
	node_popup.id_pressed.connect(_on_node_popup_item_selected)
	tool_context.tool_changed.connect(_refresh)


func _setup_tools() -> void:
	node_popup.clear()
	for i: int in node_tools.size():
		node_popup.add_icon_item(node_tools[i].icon, "")
		node_popup.set_item_tooltip(i, node_tools[i].name)


	shape_popup.clear()
	for i: int in shape_tools.size():
		var tool: Tool = shape_tools[i]
		shape_popup.add_icon_item(tool.icon, "")
		shape_popup.set_item_tooltip(i, tool.name)

	_refresh()

func _refresh() -> void:
	# Only the active tool's button should be in the pressed state.
	select_button.button_pressed = tool_context.current_tool == ToolContext.SELECT_TOOL
	shape_button.button_pressed = shape_tools.has(tool_context.current_tool)
	node_button.button_pressed = node_tools.has(tool_context.current_tool)

	node_button.icon = node_tools[current_node_tool_idx].icon
	node_button.tooltip_text = node_tools[current_node_tool_idx].name
	shape_button.icon = shape_tools[current_shape_tool_idx].icon
	shape_button.tooltip_text = shape_tools[current_shape_tool_idx].name


## Activate Shape tool
func _on_shape_button_pressed() -> void:
	tool_context.current_tool = shape_tools[current_shape_tool_idx]
	_show_popup_menu(shape_button, shape_popup)


func _show_popup_menu(button: Button, popup: PopupMenu) -> void:
	# Reset size so that size.y is accurate otherwise it may change on render
	popup.reset_size()
	var popup_upward_y: float = button.global_position.y - popup.size.y
	var spawn_position: Vector2 = Vector2(button.global_position.x, popup_upward_y)

	popup.popup(Rect2i(spawn_position, Vector2i.ZERO))


## Handles selection from the shape popup menu.
## Updates the sub-mode label and keeps the tool active.
func _on_shape_popup_item_selected(id: int) -> void:
	current_shape_tool_idx = id
	tool_context.current_tool = shape_tools[id]


## Activate Node tool
func _on_node_button_pressed() -> void:
	tool_context.current_tool = node_tools[current_node_tool_idx]
	_show_popup_menu(node_button, node_popup)


## Handles selection from the node popup menu.
func _on_node_popup_item_selected(id: int) -> void:
	current_node_tool_idx = id
	tool_context.current_tool = node_tools[id]


## Reset tool context when select is selected
func _on_select_button_pressed() -> void:
	tool_context.reset()
