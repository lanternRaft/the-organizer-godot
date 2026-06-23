extends Control

## Top-right grid toggle button.
##
## Toggles the grid background on/off. Emits a signal so the parent (Main)
## can relay the action to GridBackground.

## Emitted when the button is pressed to toggle the grid.
signal grid_toggle_requested


@onready var button: Button = $Button


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	grid_toggle_requested.emit()


## Updates the button's pressed/look state to match the grid's current visibility.
func set_grid_visible(visible_state: bool) -> void:
	button.button_pressed = not visible_state