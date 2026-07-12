## Tracks ToolContext so multiple nodes know what tool is active
extends Resource
class_name ToolContext

enum ToolTypes { SELECT, CIRCLE_NODE }


var current_tool_type: ToolTypes:
	set(value):
		current_tool_type = value
