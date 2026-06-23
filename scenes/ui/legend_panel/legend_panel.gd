extends PanelContainer

## Legend panel — auto-generated list of colors in use on the canvas, each with an editable name.
##
## Owns its state internally (color-to-name mapping, entry row nodes, group counter).
## Main calls set_colors_in_use() after every color-affecting mutation.
## Emits name_changed() when the user edits a label — Main connects this to save.

signal name_changed(color: Color, new_name: String)

## Color-to-custom-name mapping. Persisted and restored across sessions.
## Keys are Colors, values are Strings. Survives removal and re-appearance of a color.
var _color_names: Dictionary = {}

## Current row entry nodes, keyed by Color for O(1) lookup.
var _entry_rows: Dictionary = {}

## Global counter for default "Group N" names.
var _group_counter: int = 0

@onready var _entry_list: VBoxContainer = %EntryList

## Whether the legend has any colors to display. Exposed for Main to check.
var has_entries: bool = false:
	get:
		return not _entry_rows.is_empty()


func _ready() -> void:
	visible = false


## Sync entries with the given set of unique colors currently in use on the canvas.
## Adds rows for new colors with auto-generated "Group N" names.
## Removes rows for colors no longer in use (names are cached for re-appearance).
## Preserves custom names for colors that persist across refreshes.
func set_colors_in_use(colors: Array[Color]) -> void:
	# Determine which colors to add and which to remove.
	var current_colors: Array[Color] = []
	for color: Color in _entry_rows.keys():
		current_colors.append(color)

	var colors_set: Array[Color] = _deduplicate_colors(colors)

	# Remove colors no longer in use.
	for color: Color in current_colors:
		if not _color_in_array(color, colors_set):
			_remove_entry(color)

	# Add new colors.
	for color: Color in colors_set:
		if not _entry_rows.has(color):
			var label_name: String = _get_name_for_color(color)
			_add_entry(color, label_name)

	# Update visibility.
	visible = not _entry_rows.is_empty()


## Returns legend data for serialization.
## Format: [[Color, "custom_name"], ...] — deterministic ordering.
func get_legend_data() -> Array:
	var data: Array = []
	for color: Color in _color_names.keys():
		data.append([color, _color_names[color]])
	return data


## Restores custom names from saved data.
## data is an array of [Color, String] pairs.
func load_legend_data(data: Array) -> void:
	for entry: Variant in data:
		if typeof(entry) != TYPE_ARRAY:
			continue
		@warning_ignore("unsafe_cast")
		var entry_arr: Array = entry
		if entry_arr.size() < 2:
			continue
		var color_val: Variant = entry_arr[0]
		var name_val: Variant = entry_arr[1]
		if typeof(color_val) == TYPE_COLOR and typeof(name_val) == TYPE_STRING:
			_color_names[color_val] = name_val


## Clears all entries and resets the group counter.
func clear_all() -> void:
	for color: Color in _entry_rows.keys():
		_remove_entry(color)
	_color_names.clear()
	_group_counter = 0
	visible = false


## --- Private helpers ---

## Gets or generates a name for the given color.
## Checks cached custom names first; falls back to "Group N".
func _get_name_for_color(color: Color) -> String:
	if _color_names.has(color):
		return _color_names[color]
	_group_counter += 1
	var label_name: String = "Group %d" % _group_counter
	_color_names[color] = label_name
	return label_name


## Creates a row entry node for the given color and name.
func _add_entry(color: Color, label_name: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Color swatch.
	var swatch: ColorRect = ColorRect.new()
	swatch.custom_minimum_size = Vector2(16, 16)
	swatch.size = Vector2(16, 16)
	swatch.color = color
	# Make the swatch circular — use a StyleBoxFlat with rounded corners.
	var swatch_style: StyleBoxFlat = StyleBoxFlat.new()
	swatch_style.corner_radius_top_left = 8
	swatch_style.corner_radius_top_right = 8
	swatch_style.corner_radius_bottom_left = 8
	swatch_style.corner_radius_bottom_right = 8
	swatch_style.bg_color = color
	swatch.add_theme_stylebox_override("normal", swatch_style)
	# Ensure consistent visual size even after applying style.
	swatch.custom_minimum_size = Vector2(16, 16)
	# Let it shrink/grow based on the style.
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Editable name field.
	var name_field: LineEdit = LineEdit.new()
	name_field.text = label_name
	name_field.custom_minimum_size = Vector2(60, 0)
	name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_field.expand_to_text_length = true
	name_field.max_length = 64
	name_field.select_all_on_focus = true

	# Flat style — no border when not focused, subtle border on focus.
	var normal_style: StyleBoxEmpty = StyleBoxEmpty.new()
	name_field.add_theme_stylebox_override("normal", normal_style)
	var focus_style: StyleBoxFlat = StyleBoxFlat.new()
	focus_style.border_width_left = 1
	focus_style.border_width_top = 1
	focus_style.border_width_right = 1
	focus_style.border_width_bottom = 1
	focus_style.border_color = Color(0.4, 0.6, 0.9)
	focus_style.bg_color = Color(0, 0, 0, 0.05)
	name_field.add_theme_stylebox_override("focus", focus_style)
	name_field.add_theme_stylebox_override("read_only", normal_style)

	# Set font color for dark theme readability.
	var font_color: Color = Color(0.9, 0.9, 0.95)
	name_field.add_theme_color_override("font_color", font_color)
	name_field.add_theme_color_override("font_placeholder_color", font_color * 0.5)
	name_field.add_theme_color_override("caret_color", font_color)

	# Connect edit signals.
	name_field.text_submitted.connect(_on_name_submitted.bind(color, name_field))
	name_field.focus_exited.connect(_on_name_focus_exited.bind(color, name_field))

	row.add_child(swatch)
	row.add_child(name_field)
	_entry_list.add_child(row)
	_entry_rows[color] = row


## Removes the row entry for the given color.
## The custom name is preserved in _color_names for re-appearance.
func _remove_entry(color: Color) -> void:
	var row: Control = _entry_rows.get(color, null)
	if row != null:
		_entry_list.remove_child(row)
		row.queue_free()
	_entry_rows.erase(color)


## Called when the user presses Enter in a LineEdit.
func _on_name_submitted(new_name: String, color: Color, _field: LineEdit) -> void:
	_apply_name_change(color, new_name)


## Called when the LineEdit loses focus.
func _on_name_focus_exited(color: Color, _field: LineEdit) -> void:
	var row: Control = _entry_rows.get(color, null)
	if row != null:
		var name_field: LineEdit = row.get_child(1) as LineEdit
		if name_field != null:
			_apply_name_change(color, name_field.text)


## Applies a name change: updates cache, emits signal for Main to save.
func _apply_name_change(color: Color, new_name: String) -> void:
	if new_name.is_empty():
		return
	if _color_names.get(color, "") == new_name:
		return
	_color_names[color] = new_name
	name_changed.emit(color, new_name)


## Deduplicates a Color array. Godot's Color is a struct with == comparison.
func _deduplicate_colors(colors: Array[Color]) -> Array[Color]:
	var result: Array[Color] = []
	for color: Color in colors:
		if not _color_in_array(color, result):
			result.append(color)
	return result


## Checks if a Color is in an array (by value equality).
static func _color_in_array(color: Color, arr: Array[Color]) -> bool:
	for c: Color in arr:
		if c.r == color.r and c.g == color.g and c.b == color.b and c.a == color.a:
			return true
	return false