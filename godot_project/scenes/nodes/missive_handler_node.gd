class_name MissiveHandlerNode
extends Node

signal finish_turn(node:TroupsHandlerNode)
signal handler_free(node:TroupsHandlerNode)
signal handler_added(node:TroupsHandlerNode)

@onready var troups: TroupsDefinitionResource;
@onready var timer:Timer= Timer.new()
@onready var missive_node_scene = preload("MissiveNode.tscn")
var road_path_troops= []

func _ready() -> void:
	GameManager.start_new_turn.connect(play_turn)

func play_turn() -> void:
	if is_queued_for_deletion():
		return
	troups.spawned_quantity =0
	troups.step += 1
	if troups.step+1 > troups.road_path.size()-1 :
		printerr("❌ MissiveHandlerNode: Erreur de calcul de step")
		free_handler()
		return
	
	var kingdom_departure = troups.road_path[troups.step]
	if(kingdom_departure.kingdom.owner_index != troups.owner_index):
		free_handler()
		return

	create_timer()

func spawn() -> void:
	var missive_node = missive_node_scene.instantiate()
	missive_node.troupsOrigin = troups
	
	if troups.step+1 > troups.road_path.size()-1 :
		printerr("Missive_handler_node: Erreur de calcul de step")
		return


	missive_node.global_position = troups.road_path[troups.step].global_position
	missive_node.top_level=true
	add_child(missive_node)
	missive_node.died.connect(on_missive_died);
	missive_node.arrived.connect(on_missive_arrived);
	troups.spawned_quantity += 1
	free_timer_handler()
	
func free_timer_handler():
	timer.queue_free()

func free_handler():
	handler_free.emit(self)
	queue_free()

func on_missive_arrived(_missive_node:MissiveNode):
	if troups.step+1 >= troups.road_path.size()-1:
		var troupsHandler = TroupsHandlerNode.new()
		var troups_definition = TroupsDefinitionResource.new()
		troups_definition.owner_index = troups.owner_index
		troups_definition.kingdom_departure=troups.kingdom_destination
		troups_definition.kingdom_destination=road_path_troops[road_path_troops.size()-1]
		troups_definition.quantity = ceili(troups_definition.kingdom_departure.kingdom.troups_number / 2.0)
		troups_definition.road_path = road_path_troops
		troupsHandler.troups = troups_definition
		handler_added.emit(troupsHandler)
		free_handler()
	else:
		finish_turn.emit(self)

func on_missive_died(_missive_node:MissiveNode):
	free_handler()

func create_timer():
	timer = Timer.new()
	timer.timeout.connect(spawn);
	timer.autostart = true
	timer.wait_time =0.10
	add_child(timer)
