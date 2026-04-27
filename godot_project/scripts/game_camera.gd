extends Camera2D


@export var min_zoom := 1.2
@export var max_zoom := 2.0
@export var zoom_factor := 2.0
@export var zoom_duration := 0.2
@export var drag_smoothing := 20.0
@export var drag_friction := 10.0
@export var pinch_zoom_sensitivity := 0.01

var _zoom_level := 2.0
var _drag_velocity := Vector2.ZERO
var _saved_margins := {}

@onready var tween: Tween

func _ready() -> void:
	zoom = Vector2(_zoom_level, _zoom_level)
	_saved_margins = {
		"left": drag_left_margin,
		"right": drag_right_margin,
		"top": drag_top_margin,
		"bottom": drag_bottom_margin,
	}

func _disable_margins() -> void:
	drag_left_margin = 0.0
	drag_right_margin = 0.0
	drag_top_margin = 0.0
	drag_bottom_margin = 0.0

func _restore_margins() -> void:
	drag_left_margin = _saved_margins["left"]
	drag_right_margin = _saved_margins["right"]
	drag_top_margin = _saved_margins["top"]
	drag_bottom_margin = _saved_margins["bottom"]

func _process(delta: float) -> void:
	var real_delta := delta / Engine.time_scale
	if Input.is_action_just_pressed("zoom_in"):
		_set_zoom_level(_zoom_level - zoom_factor)
	elif Input.is_action_just_pressed("zoom_out"):
		_set_zoom_level(_zoom_level + zoom_factor)
	elif DragAutoload.is_pinching and DragAutoload.pinch_zoom_delta != 0.0:
		print("Pinch zooming")
		_set_zoom_level(_zoom_level - DragAutoload.pinch_zoom_delta * pinch_zoom_sensitivity)
		DragAutoload.pinch_zoom_delta = 0.0
	elif DragAutoload.is_dragging:
		_disable_margins()
		_drag_velocity = lerp(_drag_velocity, DragAutoload.drag_vector, real_delta * drag_smoothing)
		DragAutoload.drag_vector = Vector2.ZERO
	else:
		if _drag_velocity.length() > 0.5:
			_disable_margins()
		else:
			_restore_margins()
		_drag_velocity = lerp(_drag_velocity, Vector2.ZERO, real_delta * drag_friction)
		if DragAutoload.eventIndex == -1:
			global_position = lerp(global_position, get_global_mouse_position(), real_delta * 1.5)
	global_position -= _drag_velocity

func _set_zoom_level(value: float) -> void:
	_zoom_level = clamp(value, min_zoom, max_zoom)
	var zoom_level = _zoom_level
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(
		self,
		"zoom",
		Vector2(zoom_level,zoom_level),
		zoom_duration,
	).from_current().set_trans(Tween.TRANS_SINE)

