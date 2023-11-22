@tool
extends EditorPlugin

## Distance in pixels from cursor to polygon vertex when it will become active (hovered)
const CURSOR_THRESHOLD := 6.0

## Radius of vertex
const VERTEX_RADIUS := 6.0

## Color of the vertex
const VERTEX_COLOR := Color(0.0, 0.5, 1.0, 0.5)

## Color of the active (hovered) vertex
const VERTEX_ACTIVE_COLOR := Color(1.0, 1.0, 1.0)

## Color of the virtual vertex on the polygon sides when it's hovered.
## At this place new vertex will be created
const VERTEX_NEW_COLOR := Color(0.0, 1.0, 1.0, 0.5)

## Color of the polygon
const POLYGON_COLOR := Color(0.0, 0.5, 1.0, 0.2)


var _editable: Vector2ArrayResource
var _transform_to_view: Transform2D
var _transform_to_base: Transform2D
var _is_dragging := false
var _drag_started := false
var _drag_ended := false
var _drag_from: Vector2
var _drag_to: Vector2
var _can_add_at: int = -1
var _cursor: Vector2


func _edit(object):
	if object is Vector2ArrayResource:
		_editable = object
		_editable.init_polygon()
		update_overlays()
	else:
		_clear_editable()


func _handles(object):
	return object is Vector2ArrayResource


func _make_visible(visible: bool):
	update_overlays()


func _forward_canvas_draw_over_viewport(overlay: Control):
	if not is_instance_valid(_editable):
		return
	_update_transforms()
	_draw_polygon(overlay)


func _forward_canvas_gui_input(event):
	if not is_instance_valid(_editable):
		return
	var handled := _handle_left_click(event)\
		or _handle_right_click(event)\
		or _handle_mouse_move(event)
	if handled: update_overlays()
	return handled


func _handle_left_click(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if _can_add_at != -1:
				_add_vertex()
			if _editable.active_index != -1:
				_drag_started = true
				_is_dragging = true
		if event.is_released() and _editable.active_index != -1:
			_drag_ended = true
			_is_dragging = false
		return true
	return false


func _handle_right_click(event) -> bool:
	if event is InputEventMouseButton\
			and event.button_index == MOUSE_BUTTON_RIGHT\
			and event.is_pressed():
		_remove_vertex()
		return true
	return false


func _handle_mouse_move(event) -> bool:
	if event is InputEventMouseMotion:
		if _is_dragging or _drag_ended:
			_drag_vertex(_transform_to_base * event.position)
		else:
			_cursor = event.position
			_editable.active_index = _get_active_vertex()
			_can_add_at = _get_active_side()
		return true
	return false

## Returns an index of vertex when cursor is on it
func _get_active_vertex() -> int:
	for index in range(0, _editable.polygon.size()):
		# vertex is active when distance from cursor to it is less than treshold
		if (_cursor - _transform_to_view * _editable.polygon[index]).length() < CURSOR_THRESHOLD:
			return index
	return -1

## Returns index of first vertex of polygon side when cursor is near the side.
## If cursor is far from polygon sides it returns -1
func _get_active_side() -> int:
	# if cursor is at vertex, then checking for sides should be ignored
	if _editable.active_index != -1:
		return -1
	var size := _editable.polygon.size()
	for index in range(0, size):
		# checking if cursor position is between polygon side vertexes
		var a := _transform_to_view * _editable.polygon[index]
		var b := _transform_to_view * _editable.polygon[index + 1 if index + 1 < size else 0]
		var ab = (b - a).length()
		var ac = (_cursor - a).length()
		var bc = (_cursor - b).length()
		if (ac + bc) - ab < CURSOR_THRESHOLD:
			# checking height of triangle on base of polygon side
			# the opposite vertex is a cursor position
			var s: float = (ab + ac + bc) * 0.5
			var A: float = sqrt(s * (s - ab) * (s - ac) * (s - bc))
			var h: float = 2.0 * A / ab
			if h < CURSOR_THRESHOLD:
				return index + 1
	return -1


func _add_vertex():
	var position: Vector2 = _transform_to_base * _cursor
	var undo := get_undo_redo()
	undo.create_action("Add vertex")
	undo.add_do_method(_editable, "add", _can_add_at, position)
	undo.add_undo_method(_editable, "remove", _can_add_at)
	undo.commit_action()
	_can_add_at = -1
	_drag_to = position


func _remove_vertex():
	# dissalow to remove vertex if there are only 3 left, as it's have no sence for polygons
	if _editable.active_index == -1 or _editable.polygon.size() < 4:
		return
	var undo := get_undo_redo()
	undo.create_action("Remove vertex")
	undo.add_do_method(_editable, "remove", _editable.active_index)
	undo.add_undo_method(_editable, "add", _editable.active_index, _editable.active_vertex)
	undo.commit_action()


## Moves active (hovered) vertex to given position
func _drag_vertex(position: Vector2):
	if _editable.active_index == -1:
		return
	_drag_to = _drag_to if _drag_ended else position.round()
	if _drag_started:
		_drag_from = _editable.active_vertex
		_drag_started = false
	if _drag_ended:
		if _drag_to != _drag_from:
			var undo := get_undo_redo()
			undo.create_action("Drag vertex")
			undo.add_do_method(_editable, "update", _editable.active_index, _drag_to)
			undo.add_undo_method(_editable, "update", _editable.active_index, _drag_from)
			undo.commit_action()
		_drag_ended = false
	_editable.update(_editable.active_index, _drag_to)

## Get transform of parent node of the editable resource and updates transforms from/to view
func _update_transforms():
	var node: Node2D = _editable.get_local_scene() as Node2D
	var transform_viewport := node.get_viewport_transform()
	var transform_canvas := node.get_canvas_transform()
	var transform_local := node.transform
	_transform_to_view = transform_viewport * transform_canvas * transform_local
	_transform_to_base = _transform_to_view.affine_inverse()


func _draw_polygon(overlay: Control):
	if not is_instance_valid(_editable):
		return
	overlay.draw_colored_polygon(_transform_to_view * _editable.polygon, POLYGON_COLOR)
	for index in range(_editable.polygon.size()):
		_draw_vertex(overlay, _transform_to_view * _editable.polygon[index], index)
	if _can_add_at != -1:
		_draw_ghost_vertex(overlay, _cursor)


func _draw_vertex(overlay: Control, position: Vector2, index: int):
	overlay.draw_circle(position, VERTEX_RADIUS, VERTEX_COLOR)
	overlay.draw_circle(position, VERTEX_RADIUS - 1.0,\
		VERTEX_ACTIVE_COLOR if index == _editable.active_index else Color(0,0,0,0))
	if index == _editable.active_index:
		overlay.draw_string(overlay.get_theme_font("font"),\
			position + Vector2(-16.0, -16.0), str(index), 1, 32.0)


func _draw_ghost_vertex(overlay: Control, position: Vector2):
	overlay.draw_circle(position, VERTEX_RADIUS, VERTEX_NEW_COLOR)


func _clear_editable():
	_editable = null
	_is_dragging = false
	_drag_started = false
	_drag_ended = false
	_can_add_at = -1
	update_overlays()
