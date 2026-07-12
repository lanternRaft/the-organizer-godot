extends Area2D

@onready var parent: CanvasElement = $".."


func _ready() -> void:
# Connect the input_event signal to itself
	input_event.connect(_on_input_event)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Check if the player left-clicks inside the CollisionShape
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				parent.dragging = true
				parent.drag_start.emit()
				#EventBus.line_drag_start.emit(get_parent())
				#is_dragging = true
				# Calculate the offset so the object doesn't awkwardly "snap" its center to the cursor
				#drag_offset = global_position - get_global_mouse_position()
			else:
				parent.dragging_stopped()
				#EventBus.line_drag_stop.emit(get_parent())
				#is_dragging = false


func _input(event: InputEvent) -> void:
	# If the user releases the mouse anywhere outside the Area2D, stop dragging
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.button_index == MOUSE_BUTTON_LEFT and not button_event.pressed:
			parent.dragging_stopped()
			#EventBus.line_drag_stop.emit(get_parent())
