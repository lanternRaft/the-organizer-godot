@tool
## Pointer adapter and renderer for a LabelShape's ellipse body.
## This Area2D owns both the sampled hit shape and the ellipse drawing so the
## visual and interactive footprints cannot drift apart.
extends ElementPointerArea

var _polygon_shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()

@onready var label_shape: LabelShape = get_parent() as LabelShape


func _ready() -> void:
	super._ready()
	label_shape.resized.connect(_sync_shape)
	_sync_shape()


func _draw() -> void:
	var stroke_color: Color
	var stroke_width: float
	if label_shape.is_selected:
		if label_shape.is_primary:
			stroke_color = label_shape.fill_color.lightened(0.4)
			stroke_width = 3.0
		else:
			stroke_color = label_shape.fill_color.lightened(0.25)
			stroke_width = 2.5
	else:
		stroke_color = label_shape.fill_color.darkened(0.4)
		stroke_width = 2.0
	draw_ellipse(Vector2.ZERO, label_shape.rx, label_shape.ry, label_shape.fill_color)
	draw_ellipse(Vector2.ZERO, label_shape.rx, label_shape.ry, stroke_color, false, stroke_width)


func _sync_shape() -> void:
	_polygon_shape.points = label_shape.build_collision_polygon()
	if _collision_shape != null:
		_collision_shape.shape = _polygon_shape
	queue_redraw()
