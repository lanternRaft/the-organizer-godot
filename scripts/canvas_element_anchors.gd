## Contains and manages the anchors for canvas elements
class_name CanvasElementAnchors
extends Node2D

var mouse_in_anchor_show: bool = false

## Tracks if we are activing dragging a line
var active_line_drag: bool = false

var element_dragging: bool = false

@onready var anchor_show_area_2d: Area2D = $"../AnchorShowArea2D"

@onready var canvas_element: CanvasElement = $".."


func _ready() -> void:
	hide()
	anchor_show_area_2d.mouse_entered.connect(_mouse_entered)
	anchor_show_area_2d.mouse_exited.connect(_mouse_exited)
	EventBus.line_drag_start.connect(_line_drag_show)
	EventBus.line_drag_stop.connect(_line_drag_hide)
	canvas_element.drag_start.connect(_element_drag_start)
	canvas_element.drag_stop.connect(_element_drag_stop)


## Handles beginning of line drag
func _element_drag_start() -> void:
	element_dragging = true
	_refresh()


func _element_drag_stop() -> void:
	element_dragging = false
	_refresh()


func _mouse_entered() -> void:
	mouse_in_anchor_show = true
	_refresh()


func _mouse_exited() -> void:
	mouse_in_anchor_show = false
	_refresh()


func _refresh() -> void:
	if active_line_drag || (not element_dragging and mouse_in_anchor_show):
		show()
	else:
		hide()


func _line_drag_show(_line_anchor: LineAnchor) -> void:
	active_line_drag = true
	_refresh()


func _line_drag_hide() -> void:
	active_line_drag = false
	_refresh()
