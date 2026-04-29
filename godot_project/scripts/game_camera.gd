extends Camera2D


@export var min_zoom := 1.0
@export var max_zoom := 1.6
@export var zoom_factor := 0.1
@export var zoom_duration := 0.2
@export var drag_smoothing := 20.0
@export var drag_friction := 10.0
@export var pinch_zoom_sensitivity := 0.01
@export_range(0.0, 1.0) var follow_margin_left := 0.6
@export_range(0.0, 1.0) var follow_margin_right := 0.6
@export_range(0.0, 1.0) var follow_margin_top := 0.6
@export_range(0.0, 1.0) var follow_margin_bottom := 0.6
@export var debug_follow_zone := true
@export_group("UI Zone")
@export_range(0.0, 1.0) var ui_zone_width := 0.22
@export_range(0.0, 1.0) var ui_zone_height := 0.08
@export var ui_zone_enabled := true
@export var debug_zones := false
@export var follow_delay := 0.3

var _zoom_level := 1.3
var _drag_velocity := Vector2.ZERO
var _follow_delay_timer := 0.0

@onready var tween: Tween

func _ready() -> void:
	zoom = Vector2(_zoom_level, _zoom_level)
	drag_left_margin = 0.0
	drag_right_margin = 0.0
	drag_top_margin = 0.0
	drag_bottom_margin = 0.0

## Returns follow margins in world pixels based on viewport ratio and current zoom.
func _follow_margins() -> Dictionary:
	var half := get_viewport_rect().size * 0.5 / zoom
	return {
		"left":   follow_margin_left   * half.x,
		"right":  follow_margin_right  * half.x,
		"top":    follow_margin_top    * half.y,
		"bottom": follow_margin_bottom * half.y,
	}

func _draw() -> void:
	if not debug_zones:
		return
	var half := get_viewport_rect().size * 0.5 / zoom
	# screen_center is the true visible center in world space
	var screen_center := get_screen_center_position()
	# offset from this node's draw origin to the screen center
	var origin := screen_center - global_position
	var m := _follow_margins()
	var rect := Rect2(origin.x - m["left"], origin.y - m["top"], m["left"] + m["right"], m["top"] + m["bottom"])
	draw_rect(rect, Color(0.0, 1.0, 0.2, 0.15), true)
	draw_rect(rect, Color(0.0, 1.0, 0.2, 0.9), false, 2.0 / zoom.x)

	var zone_w := ui_zone_width  * half.x * 2.0
	var zone_h := ui_zone_height * half.y * 2.0
	var rect2 := Rect2(origin.x + half.x - zone_w, origin.y + half.y - zone_h, zone_w, zone_h)
	draw_rect(rect2, Color(1.0, 0.5, 0.0, 0.15), true)
	draw_rect(rect2, Color(1.0, 0.5, 0.0, 0.9), false, 2.0 / zoom.x)

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
		_follow_delay_timer = 0.0
		_drag_velocity = lerp(_drag_velocity, DragAutoload.drag_vector, real_delta * drag_smoothing)
		DragAutoload.drag_vector = Vector2.ZERO
	else:
		_drag_velocity = lerp(_drag_velocity, Vector2.ZERO, real_delta * drag_friction)
		if DragAutoload.eventIndex == -1:
			_process_edge_scroll(real_delta)
		if debug_zones:
			queue_redraw()
	global_position -= _drag_velocity

func _process_edge_scroll(real_delta: float) -> void:
	var screen_center := get_screen_center_position()
	var mouse_offset := get_global_mouse_position() - screen_center
	var half := get_viewport_rect().size * 0.5 / zoom
	var in_ui_zone := ui_zone_enabled \
		and mouse_offset.x > half.x - ui_zone_width * half.x * 2.0 \
		and mouse_offset.y > half.y - ui_zone_height * half.y * 2.0
	if in_ui_zone:
		_follow_delay_timer = 0.0
		return
	var m := _follow_margins()
	var target := global_position
	var in_follow_zone := false
	if mouse_offset.x < -m["left"]:
		target.x = global_position.x + mouse_offset.x + m["left"]
		in_follow_zone = true
	elif mouse_offset.x > m["right"]:
		target.x = global_position.x + mouse_offset.x - m["right"]
		in_follow_zone = true
	if mouse_offset.y < -m["top"]:
		target.y = global_position.y + mouse_offset.y + m["top"]
		in_follow_zone = true
	elif mouse_offset.y > m["bottom"]:
		target.y = global_position.y + mouse_offset.y - m["bottom"]
		in_follow_zone = true
	if in_follow_zone:
		_follow_delay_timer += real_delta
		if _follow_delay_timer >= follow_delay:	
			var half_vp := get_viewport_rect().size * 0.5 / zoom
			target.x = clamp(target.x, limit_left + half_vp.x, limit_right - half_vp.x)
			target.y = clamp(target.y, limit_top + half_vp.y, limit_bottom - half_vp.y)
			global_position = lerp(global_position, target, real_delta * 2.0)
	else:
		_follow_delay_timer = 0.0

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
