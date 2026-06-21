extends Control

## Bottom-center toolbar with tool buttons.
## Emits signals to Main.gd when tool modes change.

signal oval_mode_toggled(active: bool)

@onready var oval_button: Button = %OvalButton


## Forward the button toggle state to Main via signal.
func _on_oval_button_toggled(toggled_on: bool) -> void:
	oval_mode_toggled.emit(toggled_on)
