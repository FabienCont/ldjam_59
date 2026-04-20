@tool
class_name FlagNode
extends Node2D

@onready var sprite_flag :AnimatedSprite2D =$AnimatedSprite2D
@onready var owner_index:int=-1:
	set=set_owner_index


func _ready() -> void:
	set_color_flag()
	
func set_owner_index(value:int) -> void:
	owner_index = value
	set_color_flag()

func set_color_flag():
	var modulate_color = Color.from_rgba8(255,255,255,255)
	if owner_index == 1:   
		modulate_color=Color.from_rgba8(255,40,44)
	elif owner_index ==0:
		modulate_color= Color.from_rgba8(48,142,232)
	
	sprite_flag.modulate = modulate_color
