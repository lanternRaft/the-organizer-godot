## Tracks ToolContext so multiple nodes know what tool is active
class_name ToolContext
extends Resource

signal tool_changed

enum ToolTypes { SELECT, CIRCLE_NODE }

const SELECT_TOOL: Tool = preload("uid://cjruthjgny6s4")

var current_tool: Tool = SELECT_TOOL:
	set(value):
		current_tool = value
		tool_changed.emit()


func reset() -> void:
	current_tool = SELECT_TOOL


func select_tool_active() -> bool:
	return current_tool == SELECT_TOOL
