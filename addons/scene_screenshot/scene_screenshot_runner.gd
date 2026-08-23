extends SceneTree
## Generic scene screenshot runner.
##
## In normal mode this behaves like the existing Run Current Scene capture.
## With --tight-crop it renders a scene into a transparent SubViewport, asks
## Godot for each visible CanvasItem's local draw rectangle, transforms those
## rectangles into a common canvas, and captures the union plus padding. The
## source scene is never modified: the framing is done with the viewport's
## canvas transform.
##
## Arguments after "--":
##   --scene  <res://...>   scene to instantiate (required)
##   --out    <absolute>    PNG destination (required)
##   --frames <int>         frames to settle per render pass (default 10)
##   --tight-crop            crop to the scene's CanvasItem bounds
##   --padding <int>        padding around a tight crop (default 32)
##   --transparent           transparent background (normally implied by crop)

const DEFAULT_FRAMES: int = 10
const DEFAULT_PADDING: int = 32
const DEFAULT_VIEWPORT_WIDTH: int = 1152
const DEFAULT_VIEWPORT_HEIGHT: int = 648

var target: String = ""
var out_path: String = ""
var max_frames: int = DEFAULT_FRAMES
var padding: int = DEFAULT_PADDING
var tight_crop: bool = false
var transparent: bool = false

var frames: int = 0
var capture_phase: int = 0
var capture_viewport: SubViewport
var scene_instance: Node
var scene_bounds: Rect2 = Rect2()
var has_scene_bounds: bool = false
var capture_size: Vector2i = Vector2i.ONE


func _initialize() -> void:
	_parse_args()
	if target.is_empty():
		push_error("scene_screenshot: missing --scene argument")
		quit(1)
		return
	if out_path.is_empty():
		push_error("scene_screenshot: missing --out argument")
		quit(1)
		return

	var packed_scene: PackedScene = ResourceLoader.load(target) as PackedScene
	if packed_scene == null:
		push_error("scene_screenshot: cannot load scene " + target)
		quit(1)
		return

	if tight_crop:
		_start_tight_capture(packed_scene)
	else:
		_start_normal_capture(packed_scene)


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index < args.size():
		var key: String = args[index]
		if key == "--scene" and index + 1 < args.size():
			target = args[index + 1]
			index += 1
		elif key == "--out" and index + 1 < args.size():
			out_path = args[index + 1]
			index += 1
		elif key == "--frames" and index + 1 < args.size():
			max_frames = maxi(1, int(args[index + 1]))
			index += 1
		elif key == "--padding" and index + 1 < args.size():
			padding = maxi(0, int(args[index + 1]))
			index += 1
		elif key == "--tight-crop":
			tight_crop = true
		elif key == "--transparent":
			transparent = true
		index += 1


func _start_normal_capture(packed_scene: PackedScene) -> void:
	scene_instance = packed_scene.instantiate()
	root.add_child(scene_instance)
	capture_phase = 1


func _start_tight_capture(packed_scene: PackedScene) -> void:
	capture_viewport = SubViewport.new()
	capture_viewport.size = _configured_viewport_size()
	capture_viewport.transparent_bg = true
	capture_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.gui_disable_input = true
	root.add_child(capture_viewport)

	# Add the scene directly to the SubViewport. This is important for Control
	# roots: their anchors and layout then resolve against the viewport rather
	# than against an artificial Node2D wrapper.
	scene_instance = packed_scene.instantiate()
	capture_viewport.add_child(scene_instance)
	capture_phase = 1


func _configured_viewport_size() -> Vector2i:
	var width: int = int(
		ProjectSettings.get_setting("display/window/size/viewport_width", DEFAULT_VIEWPORT_WIDTH)
	)
	var height: int = int(
		ProjectSettings.get_setting("display/window/size/viewport_height", DEFAULT_VIEWPORT_HEIGHT)
	)
	return Vector2i(maxi(1, width), maxi(1, height))


func _process(_delta: float) -> bool:
	frames += 1
	if frames >= max_frames:
		if capture_phase == 1:
			if tight_crop:
				_prepare_tight_capture()
				if not has_scene_bounds:
					_save_blank_capture()
				else:
					# The canvas transform changes only where the scene is rendered.
					# Give the viewport a fresh settle period after applying it.
					frames = 0
					capture_phase = 2
			else:
				_save_viewport_image(root.get_texture().get_image())
		elif capture_phase == 2:
			var rendered: Image = capture_viewport.get_texture().get_image()
			if rendered == null:
				_save_blank_capture()
			else:
				_save_tight_region(rendered)
	return false


func _prepare_tight_capture() -> void:
	scene_bounds = Rect2()
	has_scene_bounds = false
	_collect_canvas_bounds(scene_instance)
	if not has_scene_bounds:
		return

	var width: int = maxi(1, ceili(scene_bounds.size.x) + padding * 2)
	var height: int = maxi(1, ceili(scene_bounds.size.y) + padding * 2)
	capture_size = Vector2i(width, height)
	var required_viewport_size: Vector2i = _configured_viewport_size()
	capture_viewport.size = Vector2i(
		maxi(required_viewport_size.x, capture_size.x),
		maxi(required_viewport_size.y, capture_size.y)
	)
	var offset: Vector2 = Vector2(padding, padding) - scene_bounds.position
	capture_viewport.canvas_transform = Transform2D(0.0, offset)


func _collect_canvas_bounds(node: Node) -> void:
	if node is CanvasItem:
		var item: CanvasItem = node as CanvasItem
		if item.is_visible_in_tree():
			var item_transform: Transform2D = item.get_global_transform()
			var draw_rect: Rect2 = RenderingServer.debug_canvas_item_get_rect(
				item.get_canvas_item()
			)
			if draw_rect.size.x > 0.0 and draw_rect.size.y > 0.0:
				_include_bounds(_transform_rect(item_transform, draw_rect))

			# Controls have a meaningful Godot layout rectangle even when they
			# draw no primitives themselves (for example, a container holding
			# labels). Include it in the same coordinate space as draw rectangles.
			if item is Control:
				var control: Control = item as Control
				var control_rect: Rect2 = Rect2(Vector2.ZERO, control.size)
				if control_rect.size.x > 0.0 and control_rect.size.y > 0.0:
					_include_bounds(_transform_rect(item_transform, control_rect))

	for child: Node in node.get_children():
		_collect_canvas_bounds(child)


func _transform_rect(item_transform: Transform2D, rect: Rect2) -> Rect2:
	var top_left: Vector2 = item_transform * rect.position
	var top_right: Vector2 = item_transform * Vector2(rect.end.x, rect.position.y)
	var bottom_left: Vector2 = item_transform * Vector2(rect.position.x, rect.end.y)
	var bottom_right: Vector2 = item_transform * rect.end
	var min_x: float = minf(minf(top_left.x, top_right.x), minf(bottom_left.x, bottom_right.x))
	var min_y: float = minf(minf(top_left.y, top_right.y), minf(bottom_left.y, bottom_right.y))
	var max_x: float = maxf(maxf(top_left.x, top_right.x), maxf(bottom_left.x, bottom_right.x))
	var max_y: float = maxf(maxf(top_left.y, top_right.y), maxf(bottom_left.y, bottom_right.y))
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _include_bounds(rect: Rect2) -> void:
	if not has_scene_bounds:
		scene_bounds = rect
		has_scene_bounds = true
	else:
		scene_bounds = scene_bounds.merge(rect)


func _save_tight_region(rendered: Image) -> void:
	if rendered.get_width() < capture_size.x or rendered.get_height() < capture_size.y:
		_save_blank_capture()
		return
	var region: Image = rendered.get_region(Rect2i(Vector2i.ZERO, capture_size))
	_save_viewport_image(region)


func _save_blank_capture() -> void:
	var blank: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	blank.fill(Color.TRANSPARENT)
	_save_viewport_image(blank)


func _save_viewport_image(image: Image) -> void:
	var error: int = image.save_png(out_path)
	if error != OK:
		push_error(
			"scene_screenshot: could not save PNG (%s) -> %s" % [error_string(error), out_path]
		)
		quit(1)
		return
	print("GODOT_CAPTURE_SAVED " + out_path)
	quit(0)
