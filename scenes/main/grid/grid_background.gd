extends ColorRect

## Shader-based infinite grid background.
##
## Renders a uniform grid at 40 px world-spacing that extends infinitely.
## Uses a CanvasItem shader for rendering; this script handles uniform updates,
## toggle state, and persistence.

const CONFIG_PATH: String = "user://config.cfg"
const CONFIG_SECTION: String = "grid"
const CONFIG_KEY_ENABLED: String = "enabled"

## Grid spacing in world-space units.  Matches the shader default.
@export var grid_spacing: float = 40.0

## Whether the grid is currently visible.
var grid_enabled: bool = true:
	set(value):
		grid_enabled = value
		visible = value
		_save_state()
		grid_toggled.emit(value)

## Emitted when the grid is toggled on/off.
signal grid_toggled(enabled: bool)

@onready var grid_material: ShaderMaterial = material as ShaderMaterial


func _ready() -> void:
	_setup_anchors()
	_load_state()
	_update_shader_uniforms()


func _process(_delta: float) -> void:
	## Every frame, sync the camera position/zoom so the shader grid
	## always aligns with world-space coordinates.
	_update_shader_uniforms()


## Pins this ColorRect to the full viewport so it always covers the screen.
func _setup_anchors() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


## Reads the camera's current world position and zoom, then pushes them
## to the shader uniforms so the grid tracks the viewport.
func _update_shader_uniforms() -> void:
	if not is_inside_tree():
		return

	var cam: Camera2D = get_viewport().get_camera_2d()
	if not is_instance_valid(cam):
		return

	# Use the camera's global position (center of viewport).
	# The shader formula (UV - 0.5) * viewport_size * zoom + camera_position
	# expects camera_position as the world position at the screen center.
	var cam_pos: Vector2 = cam.global_position
	var zoom: Vector2 = cam.zoom

	grid_material.set_shader_parameter("camera_position", cam_pos)
	grid_material.set_shader_parameter("camera_zoom", zoom.x)  # uniform zoom
	grid_material.set_shader_parameter("grid_spacing", grid_spacing)


## Sets the dark/light theme flag on the shader.
func set_theme_dark(dark: bool) -> void:
	grid_material.set_shader_parameter("theme_dark", dark)


## Loads grid-enabled state from ConfigFile.
func _load_state() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(CONFIG_PATH)
	if err != OK:
		return  # File doesn't exist yet — use defaults.

	var saved: bool = config.get_value(CONFIG_SECTION, CONFIG_KEY_ENABLED, true)
	# Set via the setter so the property and signal fire.
	grid_enabled = saved
	visible = grid_enabled


## Persists the current grid-enabled state to ConfigFile.
func _save_state() -> void:
	var config: ConfigFile = ConfigFile.new()
	# Preserve any existing values from other sections.
	var err: int = config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		return

	config.set_value(CONFIG_SECTION, CONFIG_KEY_ENABLED, grid_enabled)
	config.save(CONFIG_PATH)