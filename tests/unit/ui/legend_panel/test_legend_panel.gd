# GdUnit generated TestSuite
class_name LegendPanelTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/ui/legend_panel/legend_panel.gd'
const __scene: PackedScene = preload("res://scenes/ui/legend_panel/legend_panel.tscn")

## Helper: creates a LegendPanel, adds it to the tree so _ready() fires, and returns it.
func _create_panel() -> PanelContainer:
	var panel: PanelContainer = __scene.instantiate()
	# Add to the root tree so @onready vars are resolved.
	get_tree().root.add_child(panel)
	await get_tree().process_frame  # Wait one frame for _ready()
	return panel


## Helper: standard test colors.
const BLUE: Color = Color(0.231, 0.51, 0.965, 1.0)
const RED: Color = Color(0.937, 0.267, 0.267, 1.0)
const GREEN: Color = Color(0.133, 0.773, 0.369, 1.0)


## Helper: sets a custom color name in the panel's internal _color_names dict.
func _set_color_name(panel: PanelContainer, color: Color, label: String) -> void:
	var color_names: Dictionary = panel.get("_color_names")
	color_names[color] = label
	panel.set("_color_names", color_names)


## Helper: calls set_colors_in_use with a properly typed Array[Color].
func _set_colors(panel: PanelContainer, colors: Array[Color]) -> void:
	panel.call("set_colors_in_use", colors)


## Test 1: legend panel appears when colors are in use.
func test_legend_panel_appears_when_colors_in_use() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE, RED])

	assert_bool(panel.visible).is_true()

	var entry_list: VBoxContainer = panel.get_node("MarginContainer/EntryList")
	assert_int(entry_list.get_child_count()).is_equal(2)

	# Check default names: first entry row child[1] is the LineEdit.
	var first_row: HBoxContainer = entry_list.get_child(0) as HBoxContainer
	var first_name_field: LineEdit = first_row.get_child(1) as LineEdit
	assert_str(first_name_field.text).is_equal("Group 1")

	var second_row: HBoxContainer = entry_list.get_child(1) as HBoxContainer
	var second_name_field: LineEdit = second_row.get_child(1) as LineEdit
	assert_str(second_name_field.text).is_equal("Group 2")

	panel.free()


## Test 2: legend panel hides when no colors in use.
func test_legend_panel_hides_when_no_colors() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE])
	_set_colors(panel, [])

	assert_bool(panel.visible).is_false()

	panel.free()


## Test 3: default names increment globally.
func test_default_names_increment_globally() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE])
	_set_colors(panel, [BLUE, RED])

	var entry_list: VBoxContainer = panel.get_node("MarginContainer/EntryList")

	var first_row: HBoxContainer = entry_list.get_child(0) as HBoxContainer
	var first_field: LineEdit = first_row.get_child(1) as LineEdit
	assert_str(first_field.text).is_equal("Group 1")

	var second_row: HBoxContainer = entry_list.get_child(1) as HBoxContainer
	var second_field: LineEdit = second_row.get_child(1) as LineEdit
	assert_str(second_field.text).is_equal("Group 2")

	panel.free()


## Test 4: cached custom name is used for new entries.
func test_cached_name_used_for_new_entries() -> void:
	var panel: PanelContainer = await _create_panel()
	# Set name in cache BEFORE adding the color.
	_set_color_name(panel, BLUE, "Sky")
	_set_colors(panel, [BLUE])

	var entry_list: VBoxContainer = panel.get_node("MarginContainer/EntryList")
	var first_field: LineEdit = (entry_list.get_child(0) as HBoxContainer).get_child(1) as LineEdit
	assert_str(first_field.text).is_equal("Sky")

	panel.free()


## Test 5: custom name survives removal and return.
func test_custom_name_survives_removal_and_return() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE, RED])
	_set_color_name(panel, BLUE, "Sky")

	# Remove Blue.
	_set_colors(panel, [RED])
	var entry_list: VBoxContainer = panel.get_node("MarginContainer/EntryList")
	assert_int(entry_list.get_child_count()).is_equal(1)

	# Add Blue back — order is now [RED, BLUE] (RED kept in place, BLUE appended).
	_set_colors(panel, [BLUE, RED])
	entry_list = panel.get_node("MarginContainer/EntryList")
	assert_int(entry_list.get_child_count()).is_equal(2)

	# Find the BLUE row by checking its color swatch (child 0).
	var blue_field: LineEdit = null
	for row_idx: int in entry_list.get_child_count():
		var row: HBoxContainer = entry_list.get_child(row_idx) as HBoxContainer
		var swatch: ColorRect = row.get_child(0) as ColorRect
		if swatch.color.is_equal_approx(BLUE):
			blue_field = row.get_child(1) as LineEdit
			break

	# Blue should still show "Sky".
	assert_str(blue_field.text).is_equal("Sky")

	panel.free()


## Test 6: LineEdit edit emits name_changed signal.
func test_lineedit_edit_emits_name_changed_signal() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE])

	# Watch for the signal using a dictionary so lambda mutation works.
	var signal_result: Dictionary = {
		"fired": false,
		"color_r": 0.0,
		"color_g": 0.0,
		"color_b": 0.0,
		"color_a": 0.0,
		"name": ""
	}
	panel.connect("name_changed", func(color: Color, new_name: String) -> void:
		signal_result["fired"] = true
		# Store components individually so we can assert without unsafe casts.
		signal_result["color_r"] = color.r
		signal_result["color_g"] = color.g
		signal_result["color_b"] = color.b
		signal_result["color_a"] = color.a
		signal_result["name"] = new_name
	)

	# Simulate a name change by calling the internal apply function.
	panel.call("_apply_name_change", BLUE, "Oceans")

	assert_bool(signal_result["fired"]).is_true()
	assert_float(signal_result["color_r"]).is_equal_approx(BLUE.r, 0.001)
	assert_float(signal_result["color_g"]).is_equal_approx(BLUE.g, 0.001)
	assert_float(signal_result["color_b"]).is_equal_approx(BLUE.b, 0.001)
	assert_float(signal_result["color_a"]).is_equal_approx(BLUE.a, 0.001)
	assert_str(signal_result["name"]).is_equal("Oceans")

	panel.free()


## Test 7: duplicate colors not duplicated.
func test_duplicate_colors_not_duplicated() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE, BLUE, BLUE])

	var entry_list: VBoxContainer = panel.get_node("MarginContainer/EntryList")
	assert_int(entry_list.get_child_count()).is_equal(1)

	panel.free()


## Test 8: serialize legend data.
func test_serialize_legend_data() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE, RED])
	_set_color_name(panel, BLUE, "Sky")
	_set_color_name(panel, RED, "Danger")

	var data: Array = panel.call("get_legend_data")

	# Should contain 2 entries, one for each color that has a cached name.
	assert_int(data.size()).is_equal(2)

	# Find the entries by color.
	var found_sky: bool = false
	var found_danger: bool = false
	for entry: Variant in data:
		# Entry is expected to be a 2-element Array [Color, String].
		if typeof(entry) == TYPE_ARRAY:
			var entry_arr: Array = entry
			if entry_arr.size() >= 2:
				var entry_b: Color = entry_arr[0]
				var entry_n: String = entry_arr[1]
				if entry_b.is_equal_approx(BLUE) and entry_n == "Sky":
					found_sky = true
				if entry_b.is_equal_approx(RED) and entry_n == "Danger":
					found_danger = true

	assert_bool(found_sky).is_true()
	assert_bool(found_danger).is_true()

	panel.free()


## Test 9: deserialize restores custom names.
func test_deserialize_restores_custom_names() -> void:
	var panel: PanelContainer = await _create_panel()
	panel.call("load_legend_data", [[BLUE, "Sky"]])
	_set_colors(panel, [BLUE])

	var entry_list: VBoxContainer = panel.get_node("MarginContainer/EntryList")
	var first_field: LineEdit = (entry_list.get_child(0) as HBoxContainer).get_child(1) as LineEdit
	assert_str(first_field.text).is_equal("Sky")

	panel.free()


## Test 10: clear_all resets everything.
func test_clear_all_resets_everything() -> void:
	var panel: PanelContainer = await _create_panel()
	_set_colors(panel, [BLUE, RED])
	_set_color_name(panel, BLUE, "Sky")
	_set_color_name(panel, RED, "Danger")

	panel.call("clear_all")

	# Panel should be hidden.
	assert_bool(panel.visible).is_false()

	# Adding a new color should start from "Group 1" again.
	_set_colors(panel, [BLUE])
	var entry_list: VBoxContainer = panel.get_node("MarginContainer/EntryList")
	var first_field: LineEdit = (entry_list.get_child(0) as HBoxContainer).get_child(1) as LineEdit
	assert_str(first_field.text).is_equal("Group 1")

	panel.free()