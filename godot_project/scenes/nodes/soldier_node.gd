class_name SoldierNode
extends Node2D

@onready var collision_area = $Area2D
@onready var sprite = $AnimatedSprite2D

@onready var texture_enemy = preload("res://assets/sprites/char_16_16_enemy.aseprite")
signal died(soldier_node:SoldierNode)
signal arrived(soldier_node:SoldierNode)

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	collision_area.area_entered.connect(on_collide)
	var index = rng.randi_range(0, 2)
	if(index == 0):
		AudioManager.play_sfx(AudioManager.SFX_WALK)
	elif index==1: 
		AudioManager.play_sfx(AudioManager.SFX_WALK_1)
	else:
		AudioManager.play_sfx(AudioManager.SFX_WALK_2)
	set_enemy_texture()

var _resolved: bool = false

var troupsOrigin = TroupsDefinitionResource:
	set=set_troups_origin

func set_troups_origin(value:TroupsDefinitionResource)->void:
	troupsOrigin=value
	set_enemy_texture()

func set_enemy_texture():
	if(troupsOrigin.owner_index == 1 and sprite):
		sprite.sprite_frames = texture_enemy
func _process(delta):
	if(troupsOrigin.owner_index == 1 and sprite.sprite_frames != texture_enemy):
		sprite.sprite_frames = texture_enemy
	if(troupsOrigin.step > troupsOrigin.road_path_soldier.size()-1 ):
		printerr("❌ Soldier_node:Erreur de calcul de step")
		return
	var kingdom_destination = troupsOrigin.road_path_soldier[troupsOrigin.step + 1]
	
	var direction = global_position.direction_to(kingdom_destination.kingdomNode.global_position)
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	position = position.move_toward(kingdom_destination.kingdomNode.global_position, delta * 120)

func die():
	if _resolved:
		return
	_resolved = true
	died.emit(self)
	queue_free()

func arrive():
	print("arrived")
	if _resolved:
		return
	_resolved = true
	arrived.emit(self)
	queue_free()

func on_collide(area: Area2D):
	print("soldier collide with ", area)
	var unit = area.get_parent()
	print("soldier collide with unit ", unit)
	if unit is KingdomNode:
		printerr("❌ soldier collide with kingdom")
		return
	if not unit.troupsOrigin is TroupsDefinitionResource:
		printerr("❌ soldier collide with unit without troupsOrigin")
		return
	
	if unit.troupsOrigin.owner_index != troupsOrigin.owner_index:
		die()
