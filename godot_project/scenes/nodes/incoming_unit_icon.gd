class_name IncomingUnitIcon
extends TextureRect

signal icon_hovered(icon: IncomingUnitIcon)
signal icon_unhovered(icon: IncomingUnitIcon)

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
