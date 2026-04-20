class_name SoldierNode
extends Node2D

@onready var collision_area = $Area2D
@onready var sprite = $AnimatedSprite2D

@onready var texture_enemy = preload("res://assets/sprites/char_16_16_enemy.aseprite")
signal die(soldier_node:SoldierNode)
signal arrived(soldier_node:SoldierNode)

func  _on_ready() -> void:
	collision_area.area_entered.connect(on_collide)
	if(troupsOrigin.owner_index == 1):
		sprite.sprite_frames = texture_enemy

var troupsOrigin = TroupsDefinitionResource:
	set=set_troups_origin

func set_troups_origin(value:TroupsDefinitionResource)->void:
	troupsOrigin=value
	if(troupsOrigin.owner_index == 1 and sprite):
		sprite.sprite_frames = texture_enemy

func _process(delta):
	
	if(troupsOrigin.owner_index == 1 and sprite.sprite_frames != texture_enemy):
		sprite.sprite_frames = texture_enemy
	if(troupsOrigin.step > troupsOrigin.road_path.size()-1 ):
		printerr("Erreur de calcul de step")
		print(troupsOrigin.owner_index)
		print(troupsOrigin.road_path.size())
		print(troupsOrigin.step)
		if not is_queued_for_deletion():	
			queue_free()
		return
	var kingdom_destination = troupsOrigin.road_path[troupsOrigin.step]
	if(global_position.distance_to( kingdom_destination.global_position) < 16) :
		kingdom_destination.soldier_arrived(self)
		if not is_queued_for_deletion():	
			queue_free()
	var direction = global_position.direction_to(kingdom_destination.global_position)
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	global_position = global_position.move_toward(kingdom_destination.global_position, delta * 120)

func on_collide(area: Area2D):
	var unit = area.get_parent()
	if not unit.has_meta(troupsOrigin) :
		return
	if not unit.troupsOrigin is TroupsDefinitionResource:
		return
	
	if unit.troupsOrigin.owner_index != troupsOrigin.owner_index:
		die.emit(self)
		if not is_queued_for_deletion():	
			queue_free()
