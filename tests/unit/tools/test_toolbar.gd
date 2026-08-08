extends GdUnitTestSuite
## Tests for the bottom-center Toolbar (res://scenes/tools/toolbar.gd).
##
## Covers:
##   - tool configuration (shape/node tool lists, sub-mode labels)
##   - submenu (PopupMenu) contents, tooltips and icon-size caps
##   - submenu interaction (open/sub-mode select/reset to Select)
##   - compact popup styling from the shared theme (expected display sizes)

const TOOLBAR_SCENE: PackedScene = preload("res://scenes/tools/toolbar.tscn")
const THEME: Theme = preload("res://resources/theme.tres")

var toolbar: Toolbar
var runner: GdUnitSceneRunner


func before_test() -> void:
	toolbar = auto_free(TOOLBAR_SCENE.instantiate())
	toolbar.tool_context.reset()
	runner = scene_runner(toolbar)
	runner.simulate_frames(2)


# --- Configuration -----------------------------------------------------------


func test_toolbar_configured_with_expected_tools() -> void:
	assert_int(toolbar.shape_tools.size()).is_equal(2)
	assert_int(toolbar.node_tools.size()).is_equal(2)

	assert_array(toolbar.SHAPE_SUB_MODES).contains_exactly(["oval", "circle"])
	assert_array(toolbar.NODE_SUB_MODES).contains_exactly(["circle_node", "triangle_node"])

	assert_str(toolbar.shape_tools[0].name).is_equal("Oval")
	assert_str(toolbar.shape_tools[1].name).is_equal("Circle")
	assert_str(toolbar.node_tools[0].name).is_equal("Circle Node")
	assert_str(toolbar.node_tools[1].name).is_equal("Triangle Node")


# --- Submenu contents --------------------------------------------------------


func test_submenus_have_one_item_per_tool() -> void:
	assert_int(toolbar.shape_popup.item_count).is_equal(toolbar.shape_tools.size()).is_equal(2)
	assert_int(toolbar.node_popup.item_count).is_equal(toolbar.node_tools.size()).is_equal(2)


func test_shape_submenu_tooltips_and_icons() -> void:
	for i: int in toolbar.shape_tools.size():
		assert_str(toolbar.shape_popup.get_item_tooltip(i)).is_equal(toolbar.shape_tools[i].name)
		assert_object(toolbar.shape_popup.get_item_icon(i)).is_same(toolbar.shape_tools[i].icon)


func test_node_submenu_tooltips_and_icons() -> void:
	for i: int in toolbar.node_tools.size():
		assert_str(toolbar.node_popup.get_item_tooltip(i)).is_equal(toolbar.node_tools[i].name)
		assert_object(toolbar.node_popup.get_item_icon(i)).is_same(toolbar.node_tools[i].icon)


# --- Display sizes -----------------------------------------------------------


func test_buttons_render_at_expected_minimum_size() -> void:
	var buttons: Array[Button] = [toolbar.select_button, toolbar.shape_button, toolbar.node_button]
	for button: Button in buttons:
		assert_vector(button.custom_minimum_size).is_equal(Vector2(100, 80))
		# After layout the buttons must be at least their declared minimum.
		assert_vector(button.size).is_greater_equal(Vector2(100, 80))

	# The toolbar is a single row of 80px-high buttons.
	assert_that(toolbar.size.y >= 78.0).is_equal(true)
	assert_that(toolbar.size.y <= 84.0).is_equal(true)


func test_shared_theme_styles_compact_popup_menus() -> void:
	# The compact submenu styling lives in the shared theme so every app popup
	# (toolbar submenus, hamburger menu) stays consistent. The toolbar popups
	# carry no per-node overrides for these.
	assert_int(THEME.get_font_size("font_size", "PopupMenu")).is_equal(24)
	assert_int(THEME.get_constant("h_separation", "PopupMenu")).is_equal(8)
	assert_int(THEME.get_constant("v_separation", "PopupMenu")).is_equal(4)
	# The 192px source tool icons are capped so they don't balloon the menu.
	assert_int(THEME.get_constant("icon_max_width", "PopupMenu")).is_equal(40)


# --- Behavior ----------------------------------------------------------------


func test_starts_in_select_mode() -> void:
	assert_object(toolbar.tool_context.current_tool).is_same(ToolContext.SELECT_TOOL)
	assert_that(toolbar.select_button.button_pressed).is_equal(true)
	assert_that(toolbar.shape_button.button_pressed).is_equal(false)
	assert_that(toolbar.node_button.button_pressed).is_equal(false)


func test_pressing_shape_opens_submenu_and_activates_shape_tool() -> void:
	await _open_popup(toolbar.shape_button, toolbar.shape_popup)

	assert_object(toolbar.tool_context.current_tool).is_same(toolbar.shape_tools[0])
	assert_that(toolbar.shape_popup.is_visible()).is_equal(true)
	assert_that(toolbar.shape_button.button_pressed).is_equal(true)
	assert_that(toolbar.select_button.button_pressed).is_equal(false)


func test_selecting_shape_submenu_item_switches_sub_mode() -> void:
	await _open_popup(toolbar.shape_button, toolbar.shape_popup)

	toolbar.shape_popup.id_pressed.emit(1)

	assert_int(toolbar.current_shape_tool_idx).is_equal(1)
	assert_object(toolbar.tool_context.current_tool).is_same(toolbar.shape_tools[1])
	# Button icon/tooltip reflect the newly selected sub-mode.
	assert_object(toolbar.shape_button.icon).is_same(toolbar.shape_tools[1].icon)
	assert_str(toolbar.shape_button.tooltip_text).is_equal(toolbar.shape_tools[1].name)


func test_pressing_node_opens_submenu_and_activates_node_tool() -> void:
	await _open_popup(toolbar.node_button, toolbar.node_popup)

	assert_object(toolbar.tool_context.current_tool).is_same(toolbar.node_tools[0])
	assert_that(toolbar.node_popup.is_visible()).is_equal(true)
	assert_that(toolbar.node_button.button_pressed).is_equal(true)
	assert_that(toolbar.select_button.button_pressed).is_equal(false)


func test_selecting_node_submenu_item_switches_sub_mode() -> void:
	await _open_popup(toolbar.node_button, toolbar.node_popup)

	toolbar.node_popup.id_pressed.emit(1)

	assert_int(toolbar.current_node_tool_idx).is_equal(1)
	assert_object(toolbar.tool_context.current_tool).is_same(toolbar.node_tools[1])
	assert_object(toolbar.node_button.icon).is_same(toolbar.node_tools[1].icon)
	assert_str(toolbar.node_button.tooltip_text).is_equal(toolbar.node_tools[1].name)


func test_select_button_returns_to_select_mode() -> void:
	# Activate a tool first.
	await _open_popup(toolbar.shape_button, toolbar.shape_popup)
	toolbar.shape_popup.id_pressed.emit(1)
	assert_object(toolbar.tool_context.current_tool).is_same(toolbar.shape_tools[1])

	toolbar.select_button.pressed.emit()

	assert_object(toolbar.tool_context.current_tool).is_same(ToolContext.SELECT_TOOL)
	assert_that(toolbar.select_button.button_pressed).is_equal(true)
	assert_that(toolbar.shape_button.button_pressed).is_equal(false)


# --- Helpers ---------------------------------------------------------------


## Presses the given toolbar button (opening its popup) and lets it render.
func _open_popup(button: Button, popup: PopupMenu) -> void:
	button.pressed.emit()
	await get_tree().process_frame
	assert_that(popup.is_visible()).is_equal(true)
