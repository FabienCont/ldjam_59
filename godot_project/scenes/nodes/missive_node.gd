class_name MissiveNode
extends Node2D

@onready var collision_area = $Area2D
@onready var sprite = $AnimatedSprite2D
signal died(missive_node: MissiveNode)
signal arrived(missive_node: MissiveNode)

var rng = RandomNumberGenerator.new()

func  _ready() -> void:
	collision_area.area_entered.connect(on_collide)
	var index = rng.randi_range(0, 10)
	if(index == 0):
		AudioManager.play_sfx(AudioManager.SFX_CROW)
	elif(index == 1): 
		AudioManager.play_sfx(AudioManager.SFX_CROW_1)

var _resolved: bool = false

var troupsOrigin = TroupsDefinitionResource:
	set=set_troups_origin

func set_troups_origin(value:TroupsDefinitionResource)->void:
	troupsOrigin=value

func _process(delta)-> void:
	if(troupsOrigin.step+1 > troupsOrigin.road_path_missive.size()-1 ):
		printerr("❌ Missive_node: Erreur de calcul de step")
		return
	var kingdom_destination = troupsOrigin.road_path_missive[troupsOrigin.step+1]
	
	var direction = global_position.direction_to(kingdom_destination.kingdomNode.global_position)
	if direction.x <0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	global_position = global_position.move_toward(kingdom_destination.kingdomNode.global_position, delta * 150)

func die():
	if _resolved:
		return
	_resolved = true
	died.emit(self)
	queue_free()

func arrive():
	if _resolved:
		return
	_resolved = true
	arrived.emit(self)
	queue_free()

func disable_collision():
	collision_area.set_monitorable(false)

func on_collide(area: Area2D):
	var unit = area.get_parent()
	if not unit :
		return
	if unit is KingdomNode:
		printerr("❌ missive collide with kingdom")
		return
	
	if not unit.troupsOrigin is TroupsDefinitionResource:
		printerr("❌ missive collide with unit without troupsOrigin")
		return
	
	if unit.troupsOrigin.owner_index != troupsOrigin.owner_index:
		die()
