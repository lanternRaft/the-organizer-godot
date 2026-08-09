## Keeps the AnchorShowArea2D hit zone matched to a LabelShape's ellipse using
## the same logic as SelectArea2D (sampling the rim into a ConvexPolygonShape2D),
## but scaled up so the hover/anchors halo is slightly larger than the shape.
@tool
extends Area2D

## Scale factor applied to the sampled ellipse. 1.2 makes the anchor-show hit
## zone 120% the size of the shape on both axes.
@export var shape_scale: float = 1.2

var _collision_shape: CollisionShape2D

## The LabelShape this area hugs. Null for non-LabelShape parents (e.g. CanvasNode).
@onready var label_shape: LabelShape = $".." as LabelShape


func _ready() -> void:
	# Non-LabelShape parents (circle_node, triangle_node) keep their baked shape.
	if label_shape == null:
		return
	_collision_shape = get_node_or_null("CollisionShape2D")
	if _collision_shape == null:
		return
	label_shape.resized.connect(_sync_label_shape)
	_sync_label_shape()


## Re-samples the LabelShape's ellipse rim (scaled by shape_scale) into the
## CollisionShape2D, reusing the existing ConvexPolygonShape2D resource if present.
func _sync_label_shape() -> void:
	var shape: ConvexPolygonShape2D = _collision_shape.shape as ConvexPolygonShape2D
	if shape == null:
		shape = ConvexPolygonShape2D.new()
		_collision_shape.shape = shape
	shape.points = label_shape.build_collision_polygon(shape_scale)
