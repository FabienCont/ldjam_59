class_name MissiveHandlerNode
extends Node2D

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
	print("play_turn missive handler")
	troups.spawned_quantity =0
	troups.step += 1
	print("missive troups.step:" + str(troups.step))
	create_timer()

func spawn() -> void:
	print("spwan_missive")
	var missive_node = missive_node_scene.instantiate()
	missive_node.troupsOrigin = troups
	
	
	if troups.step > troups.road_path.size()-1 :
		printerr("Erreur de calcul de step")
		print(troups.owner_index)
		print(troups.road_path.size())
		print(troups.step)
		free_handler()
		return


	missive_node.global_position = troups.kingdom_departure.global_position
	if troups.step > 0:
		missive_node.global_position = troups.road_path[troups.step-1].global_position

	missive_node.top_level=true
	add_child(missive_node)
	missive_node.die.connect(on_missive_die);
	missive_node.arrived.connect(on_missive_arrived);
	troups.spawned_quantity += 1
	free_timer_handler()
	
func free_timer_handler():
	if not timer.is_queued_for_deletion():
			timer.queue_free()

func free_handler():
	if not is_queued_for_deletion():
			queue_free()

func on_missive_arrived(_missive_node:MissiveNode):
	print("on_missive_arrived")
	if troups.step >= troups.road_path.size()-1:
		var troupsHandler = TroupsHandlerNode.new()
		var troups_definition = TroupsDefinitionResource.new()
		troups_definition.owner_index = troups.owner_index
		troups_definition.kingdom_departure=troups.kingdom_destination
		troups_definition.kingdom_destination=road_path_troops[road_path_troops.size()-1]
		troups_definition.quantity = ceili(troups_definition.kingdom_departure.kingdom.troups_number / 2.0)
		troups_definition.road_path = road_path_troops
		troupsHandler.troups = troups_definition
		troupsHandler.top_level= true
		handler_added.emit(troupsHandler)
		print("handler_added"+str(troupsHandler))
		handler_free.emit(self)
		free_handler()
	finish_turn.emit(self)

func on_missive_die(_missive_node):
	handler_free.emit(self)
	free_handler()

func create_timer():
	timer = Timer.new()
	timer.timeout.connect(spawn);
	timer.autostart = true
	timer.wait_time =0.10
	add_child(timer)
