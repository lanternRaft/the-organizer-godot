## Unifies all pointer input (mouse + touch) into a single pipeline.
##
## Physics-queries ElementLayer on pointer down to find the topmost Area2D,
## walks up to the owning element node, and dispatches to its handle_click /
## handle_drag_begin / handle_drag_move / handle_drag_end methods.
##
## Normalises InputEventMouseButton/Motion and InputEventScreenTouch/Drag
## into a common PointerEvent dictionary with keys:
##   world_pos, local_pos, pressed, dragged, button_index, original_event
extends Node

## Minimum pointer-move distance (in pixels) before a drag actually begins.
const DRAG_THRESHOLD: float = 5.0

## Maximum time (in milliseconds) between two clicks on the same element to register a double-click.
const DOUBLE_CLICK_TIME_MS: int = 400

## Emitted when a pointer-down lands on empty canvas area (no clickable element found).
signal empty_canvas_clicked(world_pos: Vector2)

## Emitted when a pointer-up occurs while no drag is active (used by ArrowManager).
signal pointer_up(world_pos: Vector2)

## Reference to the element container used for physics queries.
@onready var element_layer: Node2D = %ElementLayer

## Currently active drag target (if any).
var _drag_target: Node2D = null

## World position where the drag started.
var _drag_origin: Vector2 = Vector2.ZERO

## Whether a drag is currently active (handle_drag_begin returned true).
var _drag_active: bool = false

## Whether the drag threshold has been exceeded (actual drag movement started).
var _drag_threshold_met: bool = false

## The last pointer-down position, used for threshold checks.
var _pointer_down_pos: Vector2 = Vector2.ZERO

## The last element clicked (used for double-click detection).
var _last_clicked_element: Node = null

## Timestamp of the last click (in milliseconds), used for double-click detection.
var _last_click_time: int = 0


func _unhandled_input(event: InputEvent) -> void:
	## Keyboard events (Escape etc.) are intentionally left for Main.gd.
	## Only handle mouse-button and mouse-motion events here.

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_pointer_down(mb)
			else:
				_handle_pointer_up(mb)

	elif event is InputEventMouseMotion and _drag_active:
		_handle_drag_move(event as InputEventMouseMotion)


# ----- private helpers -------------------------------------------------------

## Responds to a left-button press: runs physics query, dispatches click + drag-begin.
## Also releases GUI focus so that legend labels and text overlays exit edit mode
## when the user clicks on the canvas (Node2D/Area2D nodes don't trigger focus loss naturally).
func _handle_pointer_down(event: InputEventMouseButton) -> void:
	## Release GUI focus from any currently focused Control before canvas processing.
	## This triggers focus_exited on legend LineEdits and the TextEdit overlay,
	## which commit/revert their edits. GUI-captured Control clicks never reach
	## _unhandled_input, so clicking a legend label itself doesn't release focus here.
	var focused_input: Control = 	get_viewport().gui_get_focus_owner()
	if focused_input != null:
		focused_input.release_focus()

	var world_pos: Vector2 = element_layer.get_global_mouse_position()
	_pointer_down_pos = world_pos

	## -- Physics point query -------------------------------------------------
	var space_state: PhysicsDirectSpaceState2D = element_layer.get_world_2d().direct_space_state
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 1
	query.collide_with_areas = true
	var results: Array[Dictionary] = space_state.intersect_point(query)

	var hit_element: Node = null
	var local_pos: Vector2 = Vector2.ZERO

	if not results.is_empty():
		var collider: Variant = results[0].get("collider", null)
		var candidate: Node = null
		if collider is Area2D:
			var area: Area2D = collider
			candidate = area.get_parent()

		# Walk up if the Area2D is nested (defensive — currently Area2D is a
		# direct child of the element node).
		while candidate != null and not candidate.is_in_group("clickable") \
				and not candidate.has_method("handle_click"):
			candidate = candidate.get_parent()
			if candidate == element_layer or candidate is CanvasLayer:
				candidate = null
				break

		if candidate != null and candidate is Node2D:
			hit_element = candidate
			local_pos = (candidate as Node2D).to_local(world_pos)

	## -- Build PointerEvent dictionary ---------------------------------------
	var pointer_event: Dictionary = {
		"world_pos": world_pos,
		"local_pos": local_pos,
		"pressed": true,
		"dragged": false,
		"button_index": event.button_index,
		"original_event": event,
	}

	if hit_element != null:
		# 1. Double-click detection — same element within 400ms.
		var now: int = Time.get_ticks_msec()
		var is_double_click: bool = (
			hit_element == _last_clicked_element
			and now - _last_click_time < DOUBLE_CLICK_TIME_MS
		)
		_last_clicked_element = hit_element
		_last_click_time = now

		if is_double_click and hit_element.has_method("handle_double_click"):
			hit_element.call("handle_double_click", pointer_event)
			get_viewport().set_input_as_handled()
			return

		# 1. Check if element is already selected — if so, skip click processing
		#    to preserve multi-selection and go straight to drag setup.
		var drag_started: bool = false
		if hit_element.has_method("handle_drag_begin"):
			drag_started = hit_element.call("handle_drag_begin", pointer_event)

		if drag_started and hit_element is Node2D:
			# Element was already selected — preserve multi-selection, start drag.
			_drag_target = hit_element as Node2D
			_drag_origin = world_pos
			_drag_active = true
			_drag_threshold_met = false
			get_viewport().set_input_as_handled()
			return

		# 2. Element was not already selected — process click normally.
		var click_consumed: bool = false
		if hit_element.has_method("handle_click"):
			click_consumed = hit_element.call("handle_click", pointer_event)

		# 3. After click, try to start a drag (element may now be selected).
		if hit_element.has_method("handle_drag_begin"):
			drag_started = hit_element.call("handle_drag_begin", pointer_event)

		if drag_started and hit_element is Node2D:
			_drag_target = hit_element as Node2D
			_drag_origin = world_pos
			_drag_active = true
			_drag_threshold_met = false

		if click_consumed or drag_started:
			get_viewport().set_input_as_handled()
		return

	## -- Secondary path: arrow hit detection ---------------------------------
	## If the physics query found nothing (no Area2D), try arrow and anchor dots.
	var main: Node = get_parent()
	var handled: bool = false

	if main.has_method("_on_arrow_clicked_at"):
		handled = main.call("_on_arrow_clicked_at", world_pos)

	if not handled and main.has_method("_on_anchor_dot_mousedown"):
		# ArrowManager checks if click is on an anchor dot to begin arrow drag.
		handled = main.call("_on_anchor_dot_mousedown", world_pos)

	if not handled:
		## Truly empty canvas — let Main decide what to do.
		empty_canvas_clicked.emit(world_pos)

	get_viewport().set_input_as_handled()


## Responds to left-button release: ends the drag if one is active.
func _handle_pointer_up(event: InputEventMouseButton) -> void:
	var world_pos: Vector2 = element_layer.get_global_mouse_position()

	if _drag_active and _drag_target != null:
		var local_pos: Vector2 = _drag_target.to_local(world_pos)
		var pointer_event: Dictionary = {
			"world_pos": world_pos,
			"local_pos": local_pos,
			"pressed": false,
			"dragged": _drag_threshold_met,
			"button_index": event.button_index,
			"original_event": event,
		}
		if _drag_target.has_method("handle_drag_end"):
			_drag_target.call("handle_drag_end", pointer_event)

		_drag_target = null
		_drag_active = false
		_drag_threshold_met = false
		get_viewport().set_input_as_handled()
		return

	# Notify ArrowManager of pointer-up (to end arrow drag).
	pointer_up.emit(world_pos)


## Responds to mouse motion while a drag is active.
func _handle_drag_move(event: InputEventMouseMotion) -> void:
	var world_pos: Vector2 = element_layer.get_global_mouse_position()

	# Check threshold — only start actual drag movement after DRAG_THRESHOLD px.
	if not _drag_threshold_met:
		if world_pos.distance_to(_drag_origin) >= DRAG_THRESHOLD:
			_drag_threshold_met = true
		else:
			return  # Still within threshold, ignore.

	var local_pos: Vector2 = _drag_target.to_local(world_pos)
	var pointer_event: Dictionary = {
		"world_pos": world_pos,
		"local_pos": local_pos,
		"pressed": true,
		"dragged": true,
		"button_index": MOUSE_BUTTON_LEFT,
		"original_event": event,
	}
	if _drag_target.has_method("handle_drag_move"):
		_drag_target.call("handle_drag_move", pointer_event)
		get_viewport().set_input_as_handled()
