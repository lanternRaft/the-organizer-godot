extends GdUnitTestSuite

var _controller: CameraController


func before_test() -> void:
	_controller = auto_free(CameraController.new())
	add_child(_controller)


func test_camera_moved_emitted_on_pan() -> void:
	var monitor: Object = monitor_signals(_controller)

	_controller.pan_by(Vector2(100.0, 50.0))

	assert_signal(monitor).is_emitted("camera_moved")
	assert_vector(_controller.position).is_equal(Vector2(100.0, 50.0))


func test_camera_moved_emitted_on_zoom() -> void:
	var monitor: Object = monitor_signals(_controller)

	_controller.zoom_by_factor(1.25, Vector2(400, 300))

	assert_signal(monitor).is_emitted("zoom_changed")
	assert_signal(monitor).is_emitted("camera_moved")


func test_camera_moved_emitted_on_reset() -> void:
	# First pan the camera to offset it.
	_controller.pan_by(Vector2(200.0, 100.0))

	var monitor: Object = monitor_signals(_controller)

	_controller.reset_zoom()

	assert_signal(monitor).is_emitted("camera_moved")
	assert_vector(_controller.position).is_equal(Vector2.ZERO)


func test_camera_moved_not_emitted_when_clamped() -> void:
	# Set zoom to minimum first so another zoom-out will clamp.
	_controller.zoom_level = 0.1

	var monitor: Object = monitor_signals(_controller)

	# Attempt to zoom out further — should be clamped to 0.1, zoom_by_factor returns early.
	_controller.zoom_by_factor(0.8, Vector2(400, 300))

	assert_signal(monitor).is_not_emitted("camera_moved")
