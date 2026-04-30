class_name TurnController
extends RefCounted

var handler_nodes = []
var handler_nodes_finished = []
var handler_nodes_next_round = []

func send_command(command: BaseCommandResource) -> void:
	if command is SoldierCommandResource:
		send_troup(command)
	elif command is MissiveCommandResource:
		send_missive(command)

func send_troup(command: SoldierCommandResource) -> void:
	var troups_scene = SoldierHandlerNode.new()
	troups_scene.troups = SoldierTroupsResource.new(command.kingdom_node_departure, command.kingdom_node_destination, command.owner_index, ceili(command.kingdom_node_departure.troups_number / 2.0), command.road_path_soldier)
	add_handler(troups_scene)

func send_missive(command: MissiveCommandResource) -> void:
	var troups_scene = MissiveHandlerNode.new()
	troups_scene.troups = MissiveTroupsResource.new(command.kingdom_node_departure, command.kingdom_node_destination, command.owner_index, 1, command.road_path_soldier, command.road_path_missive)
	add_handler(troups_scene)

func add_handler(troups_scene: Node) -> void:
	if not troups_scene or troups_scene.is_queued_for_deletion():
		printerr("❌ Error, add_handler is_queued_for_deletion")
		return 

	handler_nodes.append(troups_scene)
	troups_scene.finish_turn.connect(on_handler_finish_turn)
	troups_scene.handler_free.connect(on_handler_free)
	if troups_scene.has_signal("handler_added"):
		troups_scene.handler_added.connect(on_handler_added)
	GameManager.level.add_child(troups_scene)

func on_handler_finish_turn(handler):
	handler_nodes_finished.append(handler)
	check_end_turn()

func on_handler_added(handler):
	handler_nodes_next_round.append(handler)

func on_handler_free(handler):
	var index = handler_nodes.find(handler)
	if index != -1:
		handler_nodes.remove_at(index)
	check_end_turn()

func check_end_turn():
	var is_turn_finished = handler_nodes_finished.size() == handler_nodes.size()
	if is_turn_finished:
		end_turn()
		
func end_turn():
	handler_nodes_finished = []
	var next_round := handler_nodes_next_round.duplicate()
	handler_nodes_next_round = []
	GameManager._end_turn()
	for handler in next_round:
		add_handler(handler)
