@tool
class_name Flag
extends Node2D

@onready var sprite_flag :AnimatedSprite2D =$AnimatedSprite2D
@export var owner_index:int:
	set=set_owner_index


func _ready() -> void:
	sprite_flag = $AnimatedSprite2D
	set_color_flag()
	
func set_owner_index(value:int) -> void:
	owner_index = value
	set_color_flag()

func set_color_flag():
	var modulate_color = Color(255,255,255,255)
	if owner_index == 1:
	   
		modulate_color=Color(255,40,44,255)
	elif owner_index ==0:
		modulate_color= Color(55,158,255,255)
	
	modulate = modulate_color
	#sprite.material.set_shader_parameter("shader_parameter/modulate_color",modulate_color)
