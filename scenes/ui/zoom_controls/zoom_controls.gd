## Bottom-right zoom control buttons (+ / − / reset).
##
## Emits signals when buttons are pressed. The parent (Main) relays
## these to CameraController.
extends Control

## Emitted when the zoom-in (+) button is pressed.
signal zoom_in_requested
## Emitted when the zoom-out (−) button is pressed.
signal zoom_out_requested
## Emitted when the reset (⟳) button is pressed.
signal zoom_reset_requested


func _on_zoom_in_pressed() -> void:
	zoom_in_requested.emit()


func _on_zoom_out_pressed() -> void:
	zoom_out_requested.emit()


func _on_zoom_reset_pressed() -> void:
	zoom_reset_requested.emit()