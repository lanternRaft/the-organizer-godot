class_name ClickTracker
extends Node2D

## Script used by test_discovery_via_group to track handle_click invocations.
## Using a standalone script avoids creating GDScript on the fly, which doesn't
## work with typing validation.

var was_called: bool = false


func handle_click(_event: Dictionary) -> bool:
	was_called = true
	return true
