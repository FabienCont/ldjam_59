class_name IncomingUnitIcon
extends TextureRect

signal icon_hovered(icon: IncomingUnitIcon)
signal icon_unhovered(icon: IncomingUnitIcon)
signal icon_clicked(icon: IncomingUnitIcon)

@export var quantity_label: Label;
@export var turn_label: Label;
var handler  # SoldierHandlerNode or MissiveHandlerNode

func _ready() -> void:
	call_deferred("_setup_area")

func _setup_area() -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20.0, 18.0)
	shape.shape = rect
	shape.position = Vector2(10.0, 9.0)
	area.add_child(shape)
	add_child(area)
	area.mouse_entered.connect(func(): icon_hovered.emit(self))
	area.mouse_exited.connect(func(): icon_unhovered.emit(self))
	area.input_event.connect(func(_viewport, event, _shape_idx):
		if (event is InputEventScreenTouch and event.pressed) or \
				(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			icon_clicked.emit(self))
