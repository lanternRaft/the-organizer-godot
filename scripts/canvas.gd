class_name Canvas
extends Node2D

const CIRCLE_NODE_SCENE: PackedScene = preload("res://scenes/canvas_elements/circle_node.tscn")

@export var context: ToolContext = preload("uid://cgmt207kt08s4")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var input_event: InputEventMouseButton = event
		if input_event.button_index == MOUSE_BUTTON_LEFT and input_event.pressed:
			# Get the actual coordinates in the game world, accounting for camera zoom/pan
			var world_pos: Vector2 = get_global_mouse_position()
			_on_empty_canvas_clicked(world_pos)


func _on_empty_canvas_clicked(world_pos: Vector2) -> void:
	if context.current_tool_type != ToolContext.ToolTypes.SELECT:
		_place_canvas_element(world_pos)


func _place_canvas_element(placement_position: Vector2) -> void:
	var node: CanvasElement
	if context.current_tool_type == ToolContext.ToolTypes.CIRCLE_NODE:
		node = CIRCLE_NODE_SCENE.instantiate()
	else:
		node = CIRCLE_NODE_SCENE.instantiate()

	node.position = placement_position
	add_child(node)
