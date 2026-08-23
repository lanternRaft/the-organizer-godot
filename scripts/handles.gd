@tool
extends Node2D

## Resize controller for shapes. Owns all resize geometry for the four corner
## handles hanging off this node:
##   - repositions the handles as the shape's rx/ry change
##   - computes new bounds from the grabbed corner and the pointer while dragging
##   - snaps to 10px, clamps to [20, 500] and enforces circle mode
##
## Each ResizeHandle (a Control) captures pointer input and forwards it here;
## this manager intentionally bypasses the shape's body-drag pipeline.

const MIN_SIZE: float = 20.0
const MAX_SIZE: float = 500.0
const SNAP: float = 10.0

var _shape: LabelShape = null
var _handles: Array[ResizeHandle] = []
var _active_corner: int = -1


func _ready() -> void:
	_shape = get_parent() as LabelShape
	if _shape == null:
		return
	_handles.clear()
	for child: Node in get_children():
		if child is ResizeHandle:
			_handles.append(child as ResizeHandle)
	if not _shape.resized.is_connected(_sync_handles):
		_shape.resized.connect(_sync_handles)
	_sync_handles()


# ----- Input interface (called by each ResizeHandle) -------------------------


func handle_resize_start(corner: int) -> void:
	if _shape == null:
		return
	_active_corner = corner


func is_resizing() -> bool:
	return _active_corner >= 0 and _shape != null


func handle_resize_move() -> void:
	if not is_resizing():
		return
	resize_to_pointer(_active_corner, get_global_mouse_position())


func handle_resize_end() -> void:
	_active_corner = -1
	if _shape == null or not is_node_ready():
		return
	_sync_handles()


# ----- Resize math -----------------------------------------------------------


## Recomputes the shape's bounds from the grabbed corner and a world pointer,
## then applies them through the rx/ry setters (which re-flow the text and emit
## resized/anchor_changed so the collision, selection and arrow systems follow).
## Kept pointer-agnostic so it is unit-testable without a real mouse.
func resize_to_pointer(corner: int, pointer: Vector2) -> void:
	if _shape == null or not is_node_ready():
		return
	var dir: Vector2 = _corner_dir(corner)
	var fixed: Vector2 = _opposite_corner_world(corner)
	# Candidate width/height with the dragged edge on the pointer.
	var w: float = snappedf(absf(pointer.x - fixed.x), SNAP)
	var h: float = snappedf(absf(pointer.y - fixed.y), SNAP)
	# Size limits apply after snapping so the edge grid stays clean.
	w = clampf(w, MIN_SIZE, MAX_SIZE)
	h = clampf(h, MIN_SIZE, MAX_SIZE)
	if _shape.shape_mode == LabelShape.ShapeMode.CIRCLE_MODE:
		# Circle mode: both radii grow together around the fixed corner.
		var d: float = maxf(w, h)
		w = d
		h = d
	# Rebuild the rect from the fixed corner so that corner never moves.
	var rect: Rect2 = Rect2(Vector2.ZERO, Vector2(w, h))
	if dir.x > 0.0:
		rect.position.x = fixed.x
	else:
		rect.position.x = fixed.x - w
	if dir.y > 0.0:
		rect.position.y = fixed.y
	else:
		rect.position.y = fixed.y - h
	_shape.global_position = rect.get_center()
	_shape.rx = rect.size.x * 0.5
	_shape.ry = rect.size.y * 0.5
	# Keep connected arrows glued to the new rim (same as body-drag does).
	for arrow: Arrow in _shape.get_arrows():
		arrow.rebuild_path()


func _opposite_corner_world(corner: int) -> Vector2:
	var dir: Vector2 = _corner_dir(corner)
	return _shape.to_global(Vector2(-dir.x * _shape.rx, -dir.y * _shape.ry))


func _corner_dir(corner: int) -> Vector2:
	match corner:
		ResizeHandle.TOP_LEFT:
			return Vector2(-1.0, -1.0)
		ResizeHandle.TOP_RIGHT:
			return Vector2(1.0, -1.0)
		ResizeHandle.BOTTOM_LEFT:
			return Vector2(-1.0, 1.0)
		_:
			return Vector2(1.0, 1.0)


# ----- Handle layout ---------------------------------------------------------


## Positions the four handles at the shape's bounding-box corners, centered on
## the corner point. Also connected to the shape's resized signal.
func _sync_handles() -> void:
	if _shape == null or not is_node_ready():
		return
	var half: Vector2 = Vector2(_shape.rx, _shape.ry)
	var s: float = LabelShape.HANDLE_SIZE
	for handle: ResizeHandle in _handles:
		var corner: int = handle.corner
		handle.position = _corner_dir(corner) * half
		handle.size = Vector2(s, s)
