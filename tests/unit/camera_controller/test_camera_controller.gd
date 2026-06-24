# GdUnit generated TestSuite
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/main/camera_controller/camera_controller.gd'

## Helper: creates a CameraController with a Camera2D and adds to tree.
## After _ready() runs, sets the camera reference directly on the controller
## to bypass %MainCamera unique name lookup which doesn't resolve in test tree.
## Returns the controller node. The Camera2D is accessible via get_node("MainCamera").
func _create_camera_controller() -> Node:
	var script: GDScript = load(__source)
	var controller: Node = Node.new()
	controller.set_script(script)

	var camera: Camera2D = Camera2D.new()
	camera.name = "MainCamera"
	controller.add_child(camera)

	get_tree().root.add_child(controller)
	await get_tree().process_frame  # Wait one frame for _ready()

	# %MainCamera may not resolve in test tree; set camera reference directly.
	controller.set("camera", camera)

	return controller


## Helper: gets the Camera2D from the controller.
func _get_camera(controller: Node) -> Camera2D:
	return controller.get_node("MainCamera") as Camera2D


## Test 1: camera_moved emitted on pan_by().
func test_camera_moved_emitted_on_pan() -> void:
	var controller: Node = await _create_camera_controller()
	var camera: Camera2D = _get_camera(controller)
	var signal_result: Dictionary = {"fired": false}

	controller.connect("camera_moved", func() -> void:
		signal_result["fired"] = true
	)

	controller.call("pan_by", Vector2(100.0, 50.0))

	assert_bool(signal_result["fired"]).is_true()
	assert_vector(camera.position).is_equal(Vector2(100.0, 50.0))

	controller.free()


## Test 2: camera_moved emitted on zoom_by_factor().
func test_camera_moved_emitted_on_zoom() -> void:
	var controller: Node = await _create_camera_controller()
	var signal_result: Dictionary = {"zoom_fired": false, "moved_fired": false}

	controller.connect("zoom_changed", func(_level: float) -> void:
		signal_result["zoom_fired"] = true
	)
	controller.connect("camera_moved", func() -> void:
		signal_result["moved_fired"] = true
	)

	controller.call("zoom_by_factor", 1.25, Vector2(400, 300))

	assert_bool(signal_result["zoom_fired"]).is_true()
	assert_bool(signal_result["moved_fired"]).is_true()

	controller.free()


## Test 3: camera_moved emitted on reset_zoom() after a pan.
func test_camera_moved_emitted_on_reset() -> void:
	var controller: Node = await _create_camera_controller()
	var camera: Camera2D = _get_camera(controller)
	var signal_result: Dictionary = {"fired": false}

	# First pan the camera to offset it.
	controller.call("pan_by", Vector2(200.0, 100.0))

	controller.connect("camera_moved", func() -> void:
		signal_result["fired"] = true
	)

	controller.call("reset_zoom")

	assert_bool(signal_result["fired"]).is_true()
	assert_vector(camera.position).is_equal(Vector2.ZERO)

	controller.free()


## Test 4: camera_moved NOT emitted when zoom_by_factor is clamped at MIN_ZOOM.
func test_camera_moved_not_emitted_when_clamped() -> void:
	var controller: Node = await _create_camera_controller()
	var signal_result: Dictionary = {"fired": false}

	# Set zoom to minimum first so another zoom-out will clamp.
	controller.set("zoom_level", 0.1)

	controller.connect("camera_moved", func() -> void:
		signal_result["fired"] = true
	)

	# Attempt to zoom out further — should be clamped to 0.1, zoom_by_factor returns early.
	controller.call("zoom_by_factor", 0.8, Vector2(400, 300))

	assert_bool(signal_result["fired"]).is_false()

	controller.free()