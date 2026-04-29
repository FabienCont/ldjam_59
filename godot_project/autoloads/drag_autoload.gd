extends Node

var is_dragging = false
var drag_vector: Vector2

var is_pinching := false
var pinch_zoom_delta: float = 0.0

var eventIndex: int = -1
var eventLastVec: Vector2
var relativeVec : Vector2
var _touch_time: float = 0.0
const DRAG_DELAY: float = 0.15

var _touch_points: Dictionary = {}
var _last_pinch_distance: float = 0.0

func _process(delta: float) -> void:
	if eventIndex != -1:
		_touch_time += delta

func _handle_input(event) -> void:
	relativeVec = Vector2(0.0, 0.0)
	relativeVec.x = event.position.x - eventLastVec.x
	relativeVec.y = event.position.y - eventLastVec.y
	eventLastVec.x = event.position.x
	eventLastVec.y = event.position.y
	if _touch_time >= DRAG_DELAY:
		DragAutoload.drag_vector = relativeVec if DragAutoload.is_dragging else Vector2.ZERO
		DragAutoload.is_dragging = true

func _get_pinch_distance() -> float:
	var keys = _touch_points.keys()
	return _touch_points[keys[0]].distance_to(_touch_points[keys[1]])

func _input(event) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
			if _touch_points.size() == 2:
				_last_pinch_distance = _get_pinch_distance()
				is_pinching = true
				is_dragging = false
				drag_vector = Vector2.ZERO
			else:
				eventIndex = event.index
				eventLastVec.x = event.position.x
				eventLastVec.y = event.position.y
				_touch_time = 0.0
		elif not event.pressed:
			_touch_points.erase(event.index)
			if _touch_points.size() < 2:
				is_pinching = false
				pinch_zoom_delta = 0.0
				_last_pinch_distance = 0.0
			if event.index == eventIndex:
				eventIndex = -1
				relativeVec = Vector2(0, 0)
				drag_vector = relativeVec
				is_dragging = false
				_touch_time = 0.0
	elif event is InputEventScreenDrag:
		if _touch_points.has(event.index):
			_touch_points[event.index] = event.position
		if is_pinching and _touch_points.size() == 2:
			var new_distance := _get_pinch_distance()
			pinch_zoom_delta = new_distance - _last_pinch_distance
			_last_pinch_distance = new_distance
			return
		if event.index != eventIndex: return
		_handle_input(event)
