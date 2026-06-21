extends Control

## Bottom-center toolbar with tool buttons.
## Emits signals to Main.gd when tool modes change.

signal oval_mode_toggled(active: bool)
signal select_mode_toggled(active: bool)

@onready var oval_button: Button = %OvalButton
@onready var select_button: Button = %SelectButton


## Forward the button toggle state to Main via signal.
func _on_oval_button_toggled(toggled_on: bool) -> void:
	oval_mode_toggled.emit(toggled_on)


## Forward the button toggle state to Main via signal.
func _on_select_button_toggled(toggled_on: bool) -> void:
	select_mode_toggled.emit(toggled_on)
