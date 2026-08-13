extends GdUnitTestSuite
## Integration coverage for the main scene's oval placement and body dragging.

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
const OVAL_TOOL: Tool = preload("res://resources/oval_label_shape_tool.tres")

var runner: GdUnitSceneRunner
var main: Main


func before_test() -> void:
	main = MAIN_SCENE.instantiate() as Main
	runner = scene_runner(main)


func test_oval_label_can_be_added_and_dragged() -> void:
	runner.simulate_frames(1)
	# Use the same tool resource as the Oval toolbar item, then place through the
	# canvas input path so this exercises the real main scene.
	var canvas: Canvas = main.get_node("Canvas") as Canvas
	canvas.tool_context.current_tool = OVAL_TOOL
	var start_screen: Vector2 = Vector2(600.0, 400.0)
	runner.simulate_mouse_move(start_screen)
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	runner.simulate_frames(1)

	var oval: LabelShape = canvas.find_child("OvalNode", true, false) as LabelShape
	assert_object(oval).is_not_null()
	var start_position: Vector2 = oval.position

	var drag_delta: Vector2 = Vector2(120.0, 80.0)
	runner.simulate_mouse_move(start_screen)
	runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	runner.simulate_frames(1)
	runner.simulate_mouse_move(start_screen + Vector2(1.0, 1.0))
	runner.simulate_frames(1)
	runner.simulate_mouse_move(start_screen + drag_delta)
	runner.simulate_frames(1)
	assert_vector(oval.position).is_equal(start_position + drag_delta)
	runner.simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
	runner.simulate_frames(1)

	assert_vector(oval.position).is_equal(start_position + drag_delta)
