# GdUnit generated TestSuite
extends GdUnitTestSuite

# TestSuite generated from
const __source: String = "res://scenes/main/camera_controller/camera_controller.gd"

var _controller: Camera2D


# ----- Lifecycle ---------------------------------------------------------------


func before_test() -> void:
	_controller = auto_free(Camera2D.new())
	_controller.set_script(load(__source))

	get_tree().root.add_child(_controller)
	await get_tree().process_frame


func after_test() -> void:
	_controller = null


# ===== Tests ==================================================================


## Test 1: camera_moved emitted on pan_by().
func test_camera_moved_emitted_on_pan() -> void:
	var monitor: Object = monitor_signals(_controller)

	_controller.call("pan_by", Vector2(100.0, 50.0))

	assert_signal(monitor).is_emitted("camera_moved")
	assert_that(_controller.position).is_equal(Vector2(100.0, 50.0))


## Test 2: camera_moved and zoom_changed emitted on zoom_by_factor().
func test_camera_moved_emitted_on_zoom() -> void:
	var monitor: Object = monitor_signals(_controller)

	_controller.call("zoom_by_factor", 1.25, Vector2(400, 300))

	assert_signal(monitor).is_emitted("zoom_changed")
	assert_signal(monitor).is_emitted("camera_moved")


## Test 3: camera_moved emitted on reset_zoom() after a pan.
func test_camera_moved_emitted_on_reset() -> void:
	# First pan the camera to offset it.
	_controller.call("pan_by", Vector2(200.0, 100.0))

	var monitor: Object = monitor_signals(_controller)

	_controller.call("reset_zoom")

	assert_signal(monitor).is_emitted("camera_moved")
	assert_that(_controller.position).is_equal(Vector2.ZERO)


## Test 4: camera_moved NOT emitted when zoom_by_factor is clamped at MIN_ZOOM.
func test_camera_moved_not_emitted_when_clamped() -> void:
	# Set zoom to minimum first so another zoom-out will clamp.
	_controller.set("zoom_level", 0.1)

	var monitor: Object = monitor_signals(_controller)

	# Attempt to zoom out further — should be clamped to 0.1, zoom_by_factor returns early.
	_controller.call("zoom_by_factor", 0.8, Vector2(400, 300))

	assert_signal(monitor).is_not_emitted("camera_moved")
