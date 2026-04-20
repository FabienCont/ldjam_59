class_name TroupsHandlerNode
extends Node2D

signal finish_turn(node:TroupsHandlerNode)
signal handler_free(node:TroupsHandlerNode)
signal handler_added(node:TroupsHandlerNode)

@onready var troups: TroupsDefinitionResource;
@onready var timer:Timer= Timer.new()
@onready var soldier_node_scene = preload("SoldierNode.tscn")
@onready var list_soldier=[]

func _ready() -> void:
	GameManager.start_new_turn.connect(play_turn)

func play_turn() -> void:
	print("play_turn troup")
	troups.step += 1
	print("missive troups.step:" + str(troups.step))
	var kingdom_departure = troups.kingdom_departure

	if troups.step > troups.road_path.size()-1 :
		printerr("Erreur de calcul de step")
		print(troups.owner_index)
		print(troups.road_path.size())
		print(troups.step)
		free_handler()
		return

	if troups.step > 0:
		kingdom_departure = troups.road_path[troups.step-1]

	troups.quantity= ceili(kingdom_departure.kingdom.troups_number / 2.0)
	troups.spawned_quantity =0
	create_timer()

func spawn() -> void:
	var kingdom_departure = troups.kingdom_departure
	if troups.step > 0:
		kingdom_departure = troups.road_path[troups.step-1]

	if kingdom_departure.kingdom.troups_number<=1:
		troups.quantity = troups.spawned_quantity 	
		free_timer_handler()
		if list_soldier.size() == 0:
			finish_turn.emit(self)
	else:
		kingdom_departure.kingdom.troups_number -=1
		var soldier_node = soldier_node_scene.instantiate()
		soldier_node.troupsOrigin = troups
		soldier_node.global_position = kingdom_departure.global_position
		soldier_node.top_level = true
		add_child(soldier_node)
		soldier_node.die.connect(on_soldier_die);
		soldier_node.arrived.connect(on_soldier_arrived);
		list_soldier.append(soldier_node);
		troups.spawned_quantity += 1
		if troups.spawned_quantity == troups.quantity:
			free_timer_handler()

func free_timer_handler():
	if timer and not timer.is_queued_for_deletion():
			timer.queue_free()


func free_handler():
	handler_free.emit(self)
	if not is_queued_for_deletion():
		queue_free()
		
func on_soldier_die(soldier:SoldierNode):
	troups.quantity -= 1
	remove_soldier(soldier)
	if troups.quantity == 0:
		free_handler()

func on_soldier_arrived(soldier:SoldierNode):
	remove_soldier(soldier)
	print("soldier_arrived" + str(list_soldier.size()))
	if list_soldier.size() == 0:
		finish_turn.emit(self)
		if troups.step == troups.road_path.size()-1:
			free_handler()
	
func remove_soldier(soldier:SoldierNode):
	var index = list_soldier.find(soldier)
	list_soldier.remove_at(index)

func create_timer():
	timer = Timer.new()
	timer.timeout.connect(spawn);
	timer.autostart = true
	timer.wait_time =0.13
	add_child(timer)
