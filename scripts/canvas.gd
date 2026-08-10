class_name Canvas
extends Node2D

const CIRCLE_NODE_SCENE: PackedScene = preload("res://scenes/canvas_elements/circle_node.tscn")

@export var tool_context: ToolContext = preload("uid://cgmt207kt08s4")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var input_event: InputEventMouseButton = event
		if input_event.button_index == MOUSE_BUTTON_LEFT and input_event.pressed:
			# Canvas receives this only after an element's local input area has had
			# an opportunity to consume the click. Convert to world space here so
			# placement remains correct while the camera is panned or zoomed.
			_on_empty_canvas_clicked(get_global_mouse_position())
			get_viewport().set_input_as_handled()


func _on_empty_canvas_clicked(world_pos: Vector2) -> void:
	if tool_context.select_tool_active():
		# Empty-canvas clicks in Select mode clear the current selection. Keep
		# selection ownership in Main without introducing a global hit-test path.
		var main: Node = get_parent()
		if main.has_method("clear_selection"):
			main.call("clear_selection")
		return
	_place_canvas_element(world_pos)


func _place_canvas_element(placement_position: Vector2) -> void:
	var node: CanvasElement = tool_context.current_tool.scene.instantiate()

	node.position = placement_position
	# Keep elements in ElementLayer so the rest of the canvas systems can
	# discover and manipulate them.
	var element_layer: Node2D = get_node_or_null("ElementLayer") as Node2D
	if element_layer == null:
		return
	element_layer.add_child(node)
	var main: Node = get_parent()
	if main.has_method("_wire_element_signals"):
		main.call("_wire_element_signals", node)

	tool_context.reset()
