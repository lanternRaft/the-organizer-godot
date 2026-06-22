extends Control

## Bottom-center toolbar with tool buttons.
## Emits signals to Main.gd when tool modes change.

signal shape_sub_mode_changed(sub_mode: String)
signal select_mode_toggled(active: bool)

@onready var shape_menu_button: MenuButton = %ShapeMenuButton
@onready var select_button: Button = %SelectButton

## Shape sub-mode tracking and labels.
const SHAPE_SUB_MODES: Array[String] = ["oval", "circle"]
const SHAPE_LABELS: Dictionary = {
	"oval": "Oval",
	"circle": "Circle"
}

## Currently selected shape sub-mode ("oval" or "circle").
var current_shape_sub_mode: String = "oval"


func _ready() -> void:
	_setup_shape_menu()
	_update_shape_button_label()


## Configures the MenuButton's popup with Oval and Circle items.
func _setup_shape_menu() -> void:
	var popup: PopupMenu = shape_menu_button.get_popup()
	popup.clear()
	popup.add_item("Oval", 0)
	popup.add_item("Circle", 1)
	popup.id_pressed.connect(_on_shape_menu_item_selected)


## Handles selection from the shape dropdown menu.
## Updates the button label and emits the new sub-mode.
func _on_shape_menu_item_selected(id: int) -> void:
	if id >= 0 and id < SHAPE_SUB_MODES.size():
		current_shape_sub_mode = SHAPE_SUB_MODES[id]
		_update_shape_button_label()
		shape_sub_mode_changed.emit(current_shape_sub_mode)


## Updates the MenuButton text to show current sub-mode with dropdown indicator.
func _update_shape_button_label() -> void:
	shape_menu_button.text = SHAPE_LABELS[current_shape_sub_mode] + " ▾"


## Forward the button toggle state to Main via signal.
func _on_select_button_toggled(toggled_on: bool) -> void:
	select_mode_toggled.emit(toggled_on)
