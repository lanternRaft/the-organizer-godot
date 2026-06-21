extends AcceptDialog

## Confirmation dialog for destructive actions like clearing the canvas.
## Connected to Main.gd which handles the actual clearing logic.

func _ready() -> void:
	add_cancel_button("Cancel")