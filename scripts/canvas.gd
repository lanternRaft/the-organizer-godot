class_name Canvas
extends Node2D

const CIRCLE_NODE_SCENE: PackedScene = preload("res://scenes/canvas_elements/circle_node.tscn")

@export var tool_context: ToolContext = preload("uid://cgmt207kt08s4")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var input_event: InputEventMouseButton = event
		if input_event.button_index == MOUSE_BUTTON_LEFT and input_event.pressed:
			# ClickHandler handles canvas clicks after checking for elements.
			return


func _on_empty_canvas_clicked(world_pos: Vector2) -> void:
	if not tool_context.select_tool_active():
		_place_canvas_element(world_pos)


func _place_canvas_element(placement_position: Vector2) -> void:
	var node: CanvasElement = tool_context.current_tool.scene.instantiate()

	node.position = placement_position
	# Elements must live in ElementLayer so ClickHandler's physics queries and
	# the rest of the canvas systems can discover and manipulate them.
	var element_layer: Node2D = get_node_or_null("ElementLayer") as Node2D
	if element_layer == null:
		return
	element_layer.add_child(node)
	var main: Node = get_parent()
	if main.has_method("_wire_element_signals"):
		main.call("_wire_element_signals", node)

	tool_context.reset()
