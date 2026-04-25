class_name MissiveHandlerNode
extends Node

signal finish_turn(node:SoldierHandlerNode)
signal handler_free(node:SoldierHandlerNode)
signal handler_added(node:SoldierHandlerNode)

@onready var troups: MissiveTroupsResource;
@onready var timer:Timer= Timer.new()
@onready var missive_node_scene = preload("MissiveNode.tscn")

func _ready() -> void:
	GameManager.start_new_turn.connect(play_turn)

func play_turn() -> void:
	if is_queued_for_deletion():
		return
	troups.spawned_quantity =0
	troups.step += 1
	if troups.step+1 > troups.road_path_soldier.size()-1 :
		printerr("❌ MissiveHandlerNode: Erreur de calcul de step")
		free_handler()
		return
	
	var kingdom_departure = troups.road_path_soldier[troups.step]
	if(kingdom_departure.owner_index != troups.owner_index):
		free_handler()
		return

	create_timer()

func spawn() -> void:
	var missive_node = missive_node_scene.instantiate()
	missive_node.troupsOrigin = troups
	
	if troups.step+1 > troups.road_path_missive.size()-1 :
		printerr("Missive_handler_node: Erreur de calcul de step")
		return

	missive_node.global_position = troups.road_path_missive[troups.step].kingdomNode.global_position
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
	if troups.step+1 >= troups.road_path_missive.size()-1:
		var troupsHandler = SoldierHandlerNode.new()
		var road_path_soldier = troups.road_path_soldier
		troupsHandler.troups = SoldierTroupsResource.new(road_path_soldier[0], road_path_soldier[road_path_soldier.size()-1], troups.owner_index, ceili(road_path_soldier[0].troups_number / 2.0), road_path_soldier)
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
