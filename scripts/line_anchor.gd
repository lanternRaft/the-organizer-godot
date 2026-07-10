class_name LineAnchor
extends Node2D

@onready var anchor_highlight_dot: Node2D = $AnchorHighlightDot
@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	area_2d.mouse_entered.connect(show_highlight)
	area_2d.mouse_exited.connect(hide_highlight)


func show_highlight() -> void:
	anchor_highlight_dot.show()


func hide_highlight() -> void:
	anchor_highlight_dot.hide()
