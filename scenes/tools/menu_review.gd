extends Control
## Dev-only review scene for the Toolbar's hidden popup submenus.
##
## The toolbar's ShapePopup and NodePopup only open on button press, so they
## never show up in an automated screenshot. This scene instantiates the real
## toolbar and pops both submenus open (above their buttons, side-by-side) so a
## single `godot_capture` run shows exactly what they look like. Not used by
## the game itself.

@onready var toolbar: Toolbar = $Toolbar


func _ready() -> void:
	# Let the toolbar finish laying out before positioning its popups.
	_open_popups.call_deferred()


func _open_popups() -> void:
	# Mirror Toolbar._show_popup_menu so each popup sits exactly where it does
	# in the running app: directly above its own button.
	_show_above(toolbar.shape_popup, toolbar.shape_button)
	_show_above(toolbar.node_popup, toolbar.node_button)
	# Adjacent buttons could leave the two popups overlapping; slide them apart
	# so both stay fully visible in a screenshot.
	_separate_popups()


func _show_above(popup: PopupMenu, button: Button) -> void:
	popup.reset_size()
	var spawn_position: Vector2i = Vector2i(button.global_position) - Vector2i(0, popup.size.y)
	popup.popup(Rect2i(spawn_position, Vector2i.ZERO))


## Nudges the two open popups horizontally so neither covers the other.
func _separate_popups() -> void:
	const GAP: int = 12
	var shape_window: Window = toolbar.shape_popup
	var node_window: Window = toolbar.node_popup
	var shape_right: int = shape_window.position.x + shape_window.size.x
	var node_left: int = node_window.position.x
	if shape_right + GAP > node_left:
		var shift: int = ceili(float(shape_right + GAP - node_left) / 2.0)
		shape_window.position.x -= shift
		node_window.position.x += shift
