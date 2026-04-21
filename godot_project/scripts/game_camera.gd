extends Camera2D


@export var min_zoom := 1.2
@export var max_zoom := 2.0
@export var zoom_factor := 2.0
@export var zoom_duration := 0.2

var _zoom_level := 2.0 :
	set = _set_zoom_level

@onready var tween: Tween

func _ready() -> void:
	zoom = Vector2(_zoom_level,_zoom_level)
func _process(delta: float) -> void:
	if DragAutoload.is_dragging == false:
		global_position =lerp(global_position,get_global_mouse_position(),delta*1.5)
	else:
		global_position = lerp(global_position, DragAutoload.drag_vector + global_position,delta *40 )

func _set_zoom_level(value: float) -> void:
	var zoom_level= clamp(value, min_zoom, max_zoom)
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(
		self,
		"zoom",
		Vector2(zoom_level,zoom_level),
		zoom_duration,
	).from_current().set_trans(Tween.TRANS_SINE)
	


func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		_set_zoom_level(_zoom_level - zoom_factor)
	if event.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level + zoom_factor)
