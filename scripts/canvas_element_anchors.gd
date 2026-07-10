extends Node2D


@onready var anchor_show_area_2d: Area2D = $"../AnchorShowArea2D"

var active_drag: bool = false

func _ready() -> void:
	hide()
	anchor_show_area_2d.mouse_entered.connect(_show)
	anchor_show_area_2d.mouse_exited.connect(_hide)
	EventBus.line_drag_start.connect(_line_drag_show)
	EventBus.line_drag_stop.connect(_line_drag_hide)


func _show() -> void:
	show()

func _hide() -> void:
	if not active_drag:
		hide()


func _line_drag_show(_line_anchor: LineAnchor) -> void:
	active_drag = true
	_show()

func _line_drag_hide(_line_anchor: LineAnchor) -> void:
	active_drag = false
	_hide()
