class_name MissiveNode
extends Node2D

@onready var collision_area = $Area2D
@onready var sprite = $AnimatedSprite2D
signal die(missive_node: MissiveNode)
signal arrived(missive_node: MissiveNode)

var rng = RandomNumberGenerator.new()

func  _ready() -> void:
	collision_area.area_entered.connect(on_collide)
	var index = rng.randi_range(0, 10)
	if(index == 0):
		AudioManager.play_sfx(AudioManager.SFX_CROW)
	elif(index == 1): 
		AudioManager.play_sfx(AudioManager.SFX_CROW_1)

var troupsOrigin = TroupsDefinitionResource:
	set=set_troups_origin

func set_troups_origin(value:TroupsDefinitionResource)->void:
	troupsOrigin=value

func _process(delta)-> void:
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
		kingdom_destination.missive_arrived(self)
		if not is_queued_for_deletion():	
			queue_free()
	var direction = global_position.direction_to(kingdom_destination.global_position)
	if direction.x <0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	global_position = global_position.move_toward(kingdom_destination.global_position, delta * 150)
	
func on_collide(area: Area2D):
	var unit = area.get_parent()
	if not unit :
		return
	if unit is KingdomNode:
		return
	
	if not unit.troupsOrigin is TroupsDefinitionResource:
		return
	
	if unit.troupsOrigin.owner_index != troupsOrigin.owner_index:
		die.emit(self)
		if not is_queued_for_deletion():	
			queue_free()
