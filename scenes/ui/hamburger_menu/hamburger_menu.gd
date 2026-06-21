extends Control

## Top-left hamburger menu that opens a dropdown with actions.
## Currently: Clear (triggers confirmation dialog via signal).

signal clear_requested

@onready var menu_button: Button = $MenuButton
@onready var popup_menu: PopupMenu = $PopupMenu


func _ready() -> void:
	popup_menu.add_item("Clear")
	popup_menu.hide()
	popup_menu.index_pressed.connect(_on_menu_item_pressed)
	menu_button.pressed.connect(_on_button_pressed)


## Toggles the popup menu open/closed.
func _on_button_pressed() -> void:
	if popup_menu.visible:
		popup_menu.hide()
	else:
		var button_rect: Rect2 = menu_button.get_global_rect()
		popup_menu.popup(Rect2i(int(button_rect.position.x), int(button_rect.position.y + button_rect.size.y), 0, 0))


## Handles menu item selection.
func _on_menu_item_pressed(index: int) -> void:
	match index:
		0:
			clear_requested.emit()
	popup_menu.hide()