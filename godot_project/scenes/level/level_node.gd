class_name LevelNode
extends Node2D

@onready var kingdoms_node: Node2D = $Kingdoms
@onready var roads_node: Node2D = $Roads
@onready var kingdoms: Array[KingdomDefinitionResource] = []
@onready var indexPlayer:int = 0
@onready var kingdom_selected:KingdomNode = null
@onready var kingdomHighlighted:Array[KingdomNode] = []
@onready var handler_nodes = []
@onready var handler_nodes_finished = []
@onready var handler_nodes_next_round = []

func _ready() -> void:
	var dicoKingdomNeighbours: Dictionary[Node,Array] = {}
	var dicoKingdomNeighboursRoads: Dictionary[Node,Array] = {}

	var roads = roads_node.get_children().filter(func(child): return child is RoadNode);
	for road_node in roads:
		if not dicoKingdomNeighbours.has(road_node.kingdom_a):
			dicoKingdomNeighbours[road_node.kingdom_a] =[]
		if not dicoKingdomNeighbours.has(road_node.kingdom_b):
			dicoKingdomNeighbours[road_node.kingdom_b] =[]
		if not dicoKingdomNeighboursRoads.has(road_node.kingdom_a):
			dicoKingdomNeighboursRoads[road_node.kingdom_a] =[]
		if not dicoKingdomNeighboursRoads.has(road_node.kingdom_b):
			dicoKingdomNeighboursRoads[road_node.kingdom_b] =[]

		dicoKingdomNeighboursRoads[road_node.kingdom_a].append(road_node.road)
		dicoKingdomNeighboursRoads[road_node.kingdom_b].append(road_node.road)
		dicoKingdomNeighbours[road_node.kingdom_a].append(road_node.kingdom_b)
		dicoKingdomNeighbours[road_node.kingdom_b].append(road_node.kingdom_a)

	var kingdoms_children = kingdoms_node.get_children()
	for index in range(kingdoms_children.size()):
		var kingdoms_child_node = kingdoms_children[index]
		if not kingdoms_child_node is KingdomNode:
			continue
		
		var troups_number:int = 20
		if kingdoms_child_node.force_unit_number != -1:
			troups_number = kingdoms_child_node.force_unit_number
		if (index == 0):
			set_kingdom_info(kingdoms_child_node, true, 0, troups_number,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		elif index == kingdoms_children.size() - 1:
			set_kingdom_info(kingdoms_child_node, true, 1, troups_number,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		else:
			set_kingdom_info(kingdoms_child_node, false,-1, troups_number,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		kingdoms.append(kingdoms_child_node.kingdom)
		kingdoms_child_node.kingdom_selected.connect(select_kingdom)
		kingdoms_child_node.kingdom_hovered.connect(on_kingdom_hovered)
		kingdoms_child_node.kingdom_unhovered.connect(on_kingdom_unhovered)

func set_kingdom_info(kingdom_node: KingdomNode, is_castle: bool, owner_index: int, troups_number: int, neighbours: Array, neighboursRoads: Array) -> void:
	if kingdom_node == null:
		printerr("❌ Erreur : La scene ", str(kingdom_node), " n'existe pas !")
		return
	
	if kingdom_node.kingdom == null:
		printerr("❌ Erreur : La ressource KingdomDefinitionResource n'existe pas pas sur le kingdom_node ", str(kingdom_node), " !")
		return

	kingdom_node.kingdom.is_castle = is_castle
	kingdom_node.kingdom.owner_index = owner_index
	kingdom_node.kingdom.troups_number = troups_number
	kingdom_node.kingdom.neighbours = neighbours
	kingdom_node.kingdom.roads_to_neighbours = neighboursRoads
	kingdom_node.kingdom.kingdomNode = kingdom_node
	kingdom_node.update_texture()

func reset_highlight():
	for kingdom in kingdomHighlighted:
		kingdom.highlight_state = KingdomNode.HighlightState.NONE
	kingdomHighlighted = []
	if kingdom_selected:
		kingdom_selected.highlight_state = KingdomNode.HighlightState.NONE
		kingdom_selected = null

func reset_highlight_except_selected():
	for kingdom in kingdomHighlighted:
		if kingdom != kingdom_selected:
			kingdom.highlight_state = KingdomNode.HighlightState.NONE
	kingdomHighlighted = []

func on_kingdom_hovered(kingdom_node: KingdomNode) -> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	if not kingdom_selected and kingdom_node.kingdom.owner_index == indexPlayer:
		kingdom_node.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
		kingdomHighlighted.append(kingdom_node)
		return
	if kingdom_selected:
		var shortest_command = KingdomsPathSolver.get_shortest_command(kingdoms[0],kingdom_selected.kingdom,kingdom_node.kingdom,indexPlayer)
		if not shortest_command:
			return
		
		if shortest_command.road_path_soldier:
			for kingdom in shortest_command.road_path_soldier:
				if kingdom.kingdomNode == kingdom_selected:
					continue
				if kingdom.kingdomNode not in kingdomHighlighted:
					kingdom.kingdomNode.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
					kingdomHighlighted.append(kingdom.kingdomNode)
		
		if shortest_command is MissiveCommandResource:
			if shortest_command.road_path_missive:
				for kingdom in shortest_command.road_path_missive:
					if kingdom.kingdomNode == kingdom_selected:
						continue
					if kingdom.kingdomNode not in kingdomHighlighted:
						kingdom.kingdomNode.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
						kingdomHighlighted.append(kingdom.kingdomNode)



func on_kingdom_unhovered(kingdom_node: KingdomNode) -> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	if kingdom_selected == kingdom_node:
		return
	reset_highlight_except_selected()

func select_kingdom(kingdom_node: KingdomNode)-> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	if kingdom_selected == kingdom_node:
		reset_highlight()
		return
	if kingdom_selected == null and kingdom_node.kingdom.owner_index == indexPlayer:
		kingdom_selected = kingdom_node
		kingdom_node.highlight_state = KingdomNode.HighlightState.SELECTED
		return
	elif kingdom_selected != null and kingdom_node != kingdom_selected:
		var shortest_command = KingdomsPathSolver.get_shortest_command(kingdoms[0],kingdom_selected.kingdom,kingdom_node.kingdom,indexPlayer)
		print("shortest_command"+str(shortest_command))
		if not shortest_command:
			reset_highlight()
			return
		send_command(shortest_command)
		var command = BotUtils.get_command_ia(kingdoms, kingdoms[kingdoms.size() - 1], 1)
		send_command(command)
		reset_highlight()
		GameManager.play_turn()

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

func add_handler(troups_scene):
	if not troups_scene or troups_scene.is_queued_for_deletion():
		printerr("❌ Error, add_handler is_queued_for_deletion")
		return 

	handler_nodes.append(troups_scene)
	troups_scene.finish_turn.connect(on_handler_finish_turn)
	troups_scene.handler_free.connect(on_handler_free)
	if troups_scene.has_signal("handler_added"):
		troups_scene.handler_added.connect(on_handler_added)
	add_child(troups_scene)

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
		print("turn_finished"+str(is_turn_finished))
		end_turn()
		
func end_turn():
	handler_nodes_finished = []
	for handler in handler_nodes_next_round:
		add_handler(handler)
	handler_nodes_next_round = []
	GameManager.end_turn()
	var is_finish = check_game_finished()
	if is_finish:
		return
	if not is_finish and false:
		for kingdom in kingdoms:
			if kingdom.owner_index ==0 or kingdom.owner_index:
				kingdom.troups_number +=4

func check_game_finished() -> bool:
	if kingdoms[0].owner_index == 1:
		GameManager.end_game(1)
		return true
	if  kingdoms[kingdoms.size()-1].owner_index == 0 :
		GameManager.end_game(0)
		return true
	return false
	  
