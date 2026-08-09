## Manages canvas state persistence. Instantiated as a child of Main.
## Owns file I/O, serialization, and element instantiation on load.
## Returns instantiated (but unwired) elements — the caller connects signals.
class_name SaveLoadManager
extends Node

const SAVE_PATH: String = "user://canvas.save"
const TRIANGLE_NODE_SCENE: PackedScene = preload("res://scenes/canvas_elements/triangle_node.tscn")
const CIRCLE_NODE_SCENE: PackedScene = preload("res://scenes/canvas_elements/circle_node.tscn")

## Path to the ElementLayer node (under Main/Canvas).
## Set in the scene inspector.
@export var element_layer_path: NodePath

@onready var _element_layer: Node2D = %ElementLayer


## Serialises all canvas elements into a Dictionary for save.
## legend_data is an optional Array of [Color, String] pairs from the legend panel.
func serialize_canvas(legend_data: Array) -> Dictionary:
	var elements: Array[Dictionary] = []
	for child: Node in _element_layer.get_children():
		if child is CanvasElement:
			var elem: CanvasElement = child
			var pos: Vector2 = elem.position
			if child is LabelShape:
				var shape: LabelShape = child
				var color: Color = shape.fill_color
				(
					elements
					. append(
						{
							"type": "LabelShape",
							"position_x": pos.x,
							"position_y": pos.y,
							"rx": shape.rx,
							"ry": shape.ry,
							"fill_r": color.r,
							"fill_g": color.g,
							"fill_b": color.b,
							"fill_a": color.a,
							"text": shape.text_content,
							"shape_mode": shape.shape_mode,
						}
					)
				)
			elif child is CanvasNode:
				var node: CanvasNode = child as CanvasNode
				var color: Color = node.fill_color
				(
					elements
					. append(
						{
							"type": "CanvasNode",
							"position_x": pos.x,
							"position_y": pos.y,
							"fill_r": color.r,
							"fill_g": color.g,
							"fill_b": color.b,
							"fill_a": color.a,
							"shape_mode": node.shape_mode,
						}
					)
				)
	var result: Dictionary = {"elements": elements}
	if not legend_data.is_empty():
		result["legend"] = legend_data
	return result


## Writes the current canvas state to disk.
## legend_data comes from Main asking the legend panel for its data.
func save_canvas(legend_data: Array = []) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: ", SAVE_PATH)
		return
	file.store_var(serialize_canvas(legend_data))


## Loads canvas state from disk.
## Returns a Dictionary:
func load_canvas() -> Dictionary:
	var elements: Array[Node] = []
	var legend: Array = []
	if not FileAccess.file_exists(SAVE_PATH):
		return {"elements": elements, "legend": legend}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: ", SAVE_PATH)
		return {"elements": elements, "legend": legend}
	var data: Dictionary = file.get_var()

	if data.has("legend"):
		var legend_data: Variant = data["legend"]
		if typeof(legend_data) == TYPE_ARRAY:
			legend = legend_data

	for element_data: Variant in data.get("elements", []):
		if typeof(element_data) == TYPE_DICTIONARY:
			var elem: Dictionary = element_data
			if elem.get("type") == "LabelShape":
				#var shape_node: LabelShape = _instantiate_label_shape(elem)
				#if shape_node != null:
					#elements.append(shape_node)
				pass
			elif elem.get("type") == "CanvasNode":
				var canvas_node: CanvasNode = _instantiate_canvas_node(elem)
				if canvas_node != null:
					elements.append(canvas_node)

	return {"elements": elements, "legend": legend}


## Instantiates a LabelShape from serialised data, adds it to ElementLayer,
## and returns the node for the caller to wire signals.
func _instantiate_label_shape(data: Dictionary) -> LabelShape:
	pass
	var shape: LabelShape = CIRCLE_NODE_SCENE.instantiate()
	@warning_ignore("unsafe_cast")
	shape.position = Vector2(
		data.get("position_x", 0.0) as float, data.get("position_y", 0.0) as float
	)
	@warning_ignore("unsafe_cast")
	shape.rx = data.get("rx", 80.0) as float
	@warning_ignore("unsafe_cast")
	shape.ry = data.get("ry", 50.0) as float
	@warning_ignore("unsafe_cast")
	shape.fill_color = Color(
		data.get("fill_r", 0.231) as float,
		data.get("fill_g", 0.51) as float,
		data.get("fill_b", 0.965) as float,
		data.get("fill_a", 1.0) as float
	)
	#shape.shape_mode = str(data.get("shape_mode", "oval"))
	shape.text_content = str(data.get("text", ""))

	_element_layer.add_child(shape)
	return shape


## Instantiates a CanvasNode from serialised data, adds it to ElementLayer,
## and returns the node for the caller to wire signals.
## Uses the dedicated circle_node.tscn scene for circle nodes and the generic
## canvas_node.tscn for triangle nodes.
func _instantiate_canvas_node(data: Dictionary) -> CanvasNode:
	var sub_mode: String = str(data.get("sub_mode", "circle_node"))
	var node: CanvasNode
	if sub_mode == "circle_node":
		node = CIRCLE_NODE_SCENE.instantiate()
	else:
		node = TRIANGLE_NODE_SCENE.instantiate()
	var px: float = data.get("position_x", 0.0)
	var py: float = data.get("position_y", 0.0)
	node.position = Vector2(px, py)
	var fr: float = data.get("fill_r", 0.231)
	var fg: float = data.get("fill_g", 0.51)
	var fb: float = data.get("fill_b", 0.965)
	var fa: float = data.get("fill_a", 1.0)
	node.fill_color = Color(fr, fg, fb, fa)
	if data.has("shape_mode"):
		node.shape_mode = CanvasNode.ShapeMode.keys()[data.get("shape_mode")]

	_element_layer.add_child(node)
	return node
