class_name LineAnchor
extends Node2D

enum AnchorPosition { TOP, LEFT, BOTTOM, RIGHT }

@export var anchor_position: AnchorPosition

## Arrows connected to this anchor.
var connected_arrows: Array[Arrow] = []

@onready var anchor_highlight_dot: Node2D = $AnchorHighlightDot
@onready var area_2d: Area2D = $Area2D
@onready var connection_marker_2d: Marker2D = $ConnectionMarker2D
@onready var canvas_element: CanvasElement = get_parent().get_parent()


func _ready() -> void:
	canvas_element.line_anchors.push_back(self)
	area_2d.mouse_entered.connect(show_highlight)
	area_2d.mouse_exited.connect(hide_highlight)


func show_highlight() -> void:
	EventBus.anchor_highlight.emit(self)
	anchor_highlight_dot.show()


func hide_highlight() -> void:
	anchor_highlight_dot.hide()


func get_normal() -> Vector2:
	match anchor_position:
		AnchorPosition.TOP:
			return Vector2(0, -1)
		AnchorPosition.BOTTOM:
			return Vector2(0, 1)
		AnchorPosition.LEFT:
			return Vector2(-1, 0)
		AnchorPosition.RIGHT:
			return Vector2(1, 0)
		_:
			return Vector2.ZERO  # Fallback safety case


func get_line_global_position() -> Vector2:
	return connection_marker_2d.global_position
