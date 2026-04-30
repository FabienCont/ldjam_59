class_name SoldierHandlerNode
extends Node

signal finish_turn(node:SoldierHandlerNode)
signal handler_free(node:SoldierHandlerNode)

@onready var troups: SoldierTroupsResource;
@onready var timer:Timer= Timer.new()
@onready var soldier_node_scene = preload("res://scenes/nodes/SoldierNode.tscn")
@onready var list_soldier=[]

func _ready() -> void:
	GameManager.start_new_turn.connect(play_turn)
	GameManager.turn_ended.connect(on_turn_ended)
	var kingdom_departure = troups.road_path_soldier[troups.step]
	troups.quantity = ceili(kingdom_departure.troups_number / 2.0)

func on_turn_ended() -> void:
	if is_queued_for_deletion():
		return
	troups.step += 1

func play_turn() -> void:
	if is_queued_for_deletion():
		return
	if troups.step+1 > troups.road_path_soldier.size()-1 :
		printerr("❌ SoldierHandlerNode: Erreur de calcul de step")
		free_handler()
		return

	var kingdom_departure = troups.road_path_soldier[troups.step]
	if(kingdom_departure.owner_index != troups.owner_index):
		free_handler()
		return
	
	#troups.quantity= ceili(kingdom_departure.troups_number / 2.0)
	troups.spawned_quantity =0
	create_timer()

func spawn() -> void:
	var kingdom_departure = troups.road_path_soldier[troups.step]

	if kingdom_departure.troups_number<=1:
		troups.quantity = troups.spawned_quantity 	
		free_timer_handler()
		if list_soldier.size() == 0:
			free_handler()
	else:
		kingdom_departure.troups_number -=1
		var soldier_node = soldier_node_scene.instantiate()
		soldier_node.troupsOrigin = troups
		soldier_node.global_position = kingdom_departure.kingdomNode.global_position
		soldier_node.top_level = true
		soldier_node.died.connect(on_soldier_died);
		soldier_node.arrived.connect(on_soldier_arrived);
		list_soldier.append(soldier_node);
		troups.spawned_quantity += 1
		if troups.spawned_quantity >= troups.quantity:
			free_timer_handler()
		add_child(soldier_node)

func free_timer_handler():
	if timer and not timer.is_queued_for_deletion():
			timer.queue_free()


func free_handler():
	handler_free.emit(self)
	if not is_queued_for_deletion():
		queue_free()

func resolve_soldier():
	if list_soldier.size() == 0 and troups.spawned_quantity >= troups.quantity:
		if troups.step+1 >= troups.road_path_soldier.size()-1:
			free_handler()
		else :
			finish_turn.emit(self)
			
func on_soldier_died(soldier:SoldierNode):
	remove_soldier(soldier)
	resolve_soldier()

func on_soldier_arrived(soldier:SoldierNode):
	remove_soldier(soldier)
	resolve_soldier()
	
func remove_soldier(soldier:SoldierNode):
	var index = list_soldier.find(soldier)
	if index == -1:
		printerr("❌ SoldierHandlerNode: soldier not found in list_soldier")
	else:
		list_soldier.remove_at(index)

func create_timer():
	timer = Timer.new()
	timer.timeout.connect(spawn);
	timer.autostart = true
	timer.wait_time =0.13
	add_child(timer)
