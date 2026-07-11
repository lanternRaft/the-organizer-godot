class_name LineAnchor
extends Node2D

enum ANCHOR_POSITION { TOP, LEFT, BOTTOM, RIGHT }

@export var anchor_position: ANCHOR_POSITION

## Arrows connected to this anchor.
var connected_arrows: Array[Arrow] = []

@onready var anchor_highlight_dot: Node2D = $AnchorHighlightDot
@onready var area_2d: Area2D = $Area2D
@onready var connection_marker_2d: Marker2D = $ConnectionMarker2D


func _ready() -> void:
	area_2d.mouse_entered.connect(show_highlight)
	area_2d.mouse_exited.connect(hide_highlight)


## Registers an arrow as connected to this anchor.
func register_arrow(arrow: Arrow) -> void:
	connected_arrows.append(arrow)


## Unregisters an arrow from this anchor.
func unregister_arrow(arrow: Arrow) -> void:
	connected_arrows.erase(arrow)


func show_highlight() -> void:
	EventBus.anchor_highlight.emit(self)
	anchor_highlight_dot.show()


func hide_highlight() -> void:
	anchor_highlight_dot.hide()


func get_normal() -> Vector2:
	match anchor_position:
		ANCHOR_POSITION.TOP:
			return Vector2(0, -1)
		ANCHOR_POSITION.BOTTOM:
			return Vector2(0, 1)
		ANCHOR_POSITION.LEFT:
			return Vector2(-1, 0)
		ANCHOR_POSITION.RIGHT:
			return Vector2(1, 0)
		_:
			return Vector2.ZERO # Fallback safety case


func get_line_global_position() -> Vector2:
	return connection_marker_2d.global_position
	

func get_element() -> CanvasElement:
	return get_parent().get_parent()
