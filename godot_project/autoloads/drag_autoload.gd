extends Node

enum InputType { NONE, TOUCH, MOUSE }

var is_dragging = false
var drag_vector: Vector2

var is_pinching := false
var pinch_zoom_delta: float = 0.0

var eventIndex: int = -1
var eventLastVec: Vector2
var relativeVec: Vector2
var _touch_time: float = 0.0
const DRAG_DELAY: float = 0.15

var _touch_points: Dictionary = {}
var _last_pinch_distance: float = 0.0
var _active_input_type := InputType.NONE

func _process(delta: float) -> void:
	if eventIndex != -1:
		_touch_time += delta

func is_active_input_type(input_type: InputType) -> bool:
	return _active_input_type == input_type

func _begin_pointer(index: int, position: Vector2, input_type: InputType) -> void:
	if _active_input_type != InputType.NONE and _active_input_type != input_type:
		return
	_active_input_type = input_type
	if input_type == InputType.TOUCH:
		_touch_points[index] = position
		if _touch_points.size() == 2:
			_last_pinch_distance = _get_pinch_distance()
			is_pinching = true
			is_dragging = false
			drag_vector = Vector2.ZERO
			return
	eventIndex = index
	eventLastVec = position
	_touch_time = 0.0

func _end_pointer(index: int, input_type: InputType) -> void:
	if _active_input_type != input_type:
		return
	if input_type == InputType.TOUCH:
		_touch_points.erase(index)
		if _touch_points.size() < 2:
			is_pinching = false
			pinch_zoom_delta = 0.0
			_last_pinch_distance = 0.0
		if _touch_points.is_empty():
			_active_input_type = InputType.NONE
	else:
		_active_input_type = InputType.NONE
	if index == eventIndex:
		eventIndex = -1
		relativeVec = Vector2.ZERO
		drag_vector = Vector2.ZERO
		is_dragging = false
		_touch_time = 0.0

func _move_pointer(index: int, position: Vector2, input_type: InputType) -> void:
	if _active_input_type != input_type:
		return
	if input_type == InputType.TOUCH:
		if _touch_points.has(index):
			_touch_points[index] = position
		if is_pinching and _touch_points.size() == 2:
			var new_distance := _get_pinch_distance()
			pinch_zoom_delta += new_distance - _last_pinch_distance
			_last_pinch_distance = new_distance
			return
	if index != eventIndex:
		return
	_update_drag(position)

func _update_drag(position: Vector2) -> void:
	relativeVec = position - eventLastVec
	eventLastVec = position
	if _touch_time >= DRAG_DELAY:
		if not is_dragging:
			is_dragging = true
			drag_vector = Vector2.ZERO
		else:
			drag_vector += relativeVec

func _get_pinch_distance() -> float:
	var keys = _touch_points.keys()
	return _touch_points[keys[0]].distance_to(_touch_points[keys[1]])

func _input(event) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_pointer(event.index, event.position, InputType.TOUCH)
		else:
			_end_pointer(event.index, InputType.TOUCH)
	elif event is InputEventScreenDrag:
		_move_pointer(event.index, event.position, InputType.TOUCH)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer(0, event.position, InputType.MOUSE)
		else:
			_end_pointer(0, InputType.MOUSE)
	elif event is InputEventMouseMotion:
		_move_pointer(0, event.position, InputType.MOUSE)
