class_name LevelNode
extends Node2D

@onready var kingdoms_node: Node2D = $Kingdoms
@onready var roads_node: Node2D = $Roads
@onready var kingdoms: Array[KingdomNode] = []
@onready var indexPlayer:int = 0
@onready var kingdomSelected:KingdomNode = null
@onready var handler_nodes = []
@onready var handler_nodes_finished = []
@onready var handler_nodes_next_round = []

func _ready() -> void:
	
	var dicoKingdomNeighbours: Dictionary[Node,Array] = {}
	var dicoKingdomNeighboursRoads: Dictionary[Node,Array] = {}

	var roads = roads_node.get_children().filter(func(child): return child is RoadNode);
	for road in roads:
		if not dicoKingdomNeighbours.has(road.kingdom_a):
			dicoKingdomNeighbours[road.kingdom_a] =[]
		if not dicoKingdomNeighbours.has(road.kingdom_b):
			dicoKingdomNeighbours[road.kingdom_b] =[]
		if not dicoKingdomNeighboursRoads.has(road.kingdom_a):
			dicoKingdomNeighboursRoads[road.kingdom_a] =[]
		if not dicoKingdomNeighboursRoads.has(road.kingdom_b):
			dicoKingdomNeighboursRoads[road.kingdom_b] =[]

		dicoKingdomNeighboursRoads[road.kingdom_a].append(road)
		dicoKingdomNeighboursRoads[road.kingdom_b].append(road)
		dicoKingdomNeighbours[road.kingdom_a].append(road.kingdom_b)
		dicoKingdomNeighbours[road.kingdom_b].append(road.kingdom_a)


		print("dicoKingdomNeighboursRoads"+str(dicoKingdomNeighboursRoads.size()))
		print("dicoKingdomNeighbours"+str(dicoKingdomNeighbours.size()))


	for kingdoms_child_node in kingdoms_node.get_children():
		if kingdoms_child_node is KingdomNode:
			var index = kingdoms.size();
			kingdoms.append(kingdoms_child_node)
			if (index == 0):
				set_castle_info(kingdoms_child_node, true, 0, 20,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
			else:
				set_castle_info(kingdoms_child_node, false,-1, 10,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
			kingdoms_child_node.kingdom_selected.connect(select_kingdom)

	if (kingdoms.size() > 1):
		var kingdom = kingdoms[kingdoms.size() - 1]
		set_castle_info(kingdom, true,1, 20,dicoKingdomNeighbours[kingdom],dicoKingdomNeighboursRoads[kingdom])
		

func set_castle_info(kingdom_node: KingdomNode, is_castle: bool, owner_index: int, troups_number: int, neighbours: Array, neighboursRoads: Array) -> void:
	if kingdom_node == null:
		printerr("❌ Erreur : La scene ", kingdom_node, " n'existe pas !")
		return
	
	if !kingdom_node.kingdom:
		kingdom_node.kingdom = KingdomDefinitionResource.new()
	kingdom_node.kingdom.owner_index = owner_index
	kingdom_node.kingdom.troups_number = troups_number
	kingdom_node.kingdom.is_castle = is_castle
	kingdom_node.neighbours = neighbours;
	kingdom_node.roads_to_neighbours = neighboursRoads

func select_kingdom(kingdom_node: KingdomNode)-> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	print("kingdomSelected",kingdomSelected)
	print("select_kingdom",kingdom_node)
	if kingdomSelected == null and kingdom_node.kingdom.owner_index == indexPlayer:
		kingdomSelected = kingdom_node
		kingdom_node.selected = true
	elif kingdomSelected != null and kingdom_node != kingdomSelected:
		if not kingdoms.size() > 0:
			kingdomSelected.selected=false
			kingdomSelected = null
			kingdom_node.selected =false
			return
		if kingdomSelected.kingdom.is_castle == true:
			var roadsFound = find_shortest_path(kingdomSelected,kingdom_node,0, 0, [],1000000000,[])
			
			if roadsFound.size() >0: 
				send_troup(kingdomSelected,kingdom_node,roadsFound,0)
			else:
				kingdomSelected.selected=false
				kingdom_node.selected =false
				kingdomSelected = null
				return
		else:
			var roadsFoundMissive = find_shortest_path(kingdoms[0],kingdomSelected,0, 0, [],1000000000,[])
			if roadsFoundMissive.size() ==0: 
				kingdomSelected.selected=false
				kingdom_node.selected =false
				kingdomSelected = null
				return
			
			var roadsFound = find_shortest_path(kingdomSelected,kingdom_node,0, 0, [],1000000000, [])
			if roadsFound.size() ==0: 
				kingdomSelected.selected=false
				kingdom_node.selected =false
				kingdomSelected = null
				return	
			
			send_missive(kingdoms[0],kingdomSelected,roadsFoundMissive,roadsFound,0)
		print("IA START")
		play_turn_ia(1)
		print("IA STOPPED")
		GameManager.play_turn()
		kingdomSelected.selected=false
		kingdom_node.selected =false
		kingdomSelected = null
	else:
		kingdom_node.selected = false
		kingdomSelected = null

func play_turn_ia(owner_index:int):
	var possible_path = []
	var castle = kingdoms[kingdoms.size() - 1]
	if castle.kingdom.troups_number>5:
		
		var max_distance_castle=-1
		var max_distance_path=[]
		var shortest_neutral_path=[]
		var neutral_case_minimun_distance = 100000000
		var shortest_ennemy_path=[]
		var enemy_case_minimun_distance = 100000000
		var random_sort_kingdoms = kingdoms.duplicate()
		random_sort_kingdoms.shuffle()
		for kingdom_node in random_sort_kingdoms:
			if kingdom_node.kingdom.owner_index == owner_index:
				continue
			var roadsFound = find_shortest_path(castle,kingdom_node,owner_index, 0, [],1000000000, [])
			if roadsFound.size() > 0:
				possible_path.append(roadsFound)
				if roadsFound.size() > max_distance_castle:
					max_distance_castle = roadsFound.size() 
					max_distance_path = roadsFound
				if kingdom_node.kingdom.owner_index == -1:
					if neutral_case_minimun_distance < roadsFound.size():
						neutral_case_minimun_distance = roadsFound.size()
						shortest_neutral_path = roadsFound
				if kingdom_node.kingdom.owner_index == 0:
					if enemy_case_minimun_distance < roadsFound.size():
						enemy_case_minimun_distance = roadsFound.size()
						shortest_ennemy_path = roadsFound
			
		if enemy_case_minimun_distance < neutral_case_minimun_distance:
			send_troup(castle,shortest_ennemy_path[shortest_ennemy_path.size() - 1],shortest_ennemy_path,1)
			return
		elif neutral_case_minimun_distance < 100000000:
			send_troup(castle,shortest_neutral_path[shortest_neutral_path.size() - 1],shortest_neutral_path,1)
			return
		else:
			send_troup(castle,max_distance_path[max_distance_path.size() - 1],max_distance_path,1)
			return

	else:
		var own_kingdoms = kingdoms.filter(func(kingdom_node):return kingdom_node.kingdom.owner_index == owner_index)
		if own_kingdoms.size() == 0:
			return
	
		own_kingdoms.sort_custom(func(kingdom_node_a,kingdom_node_b): return kingdom_node_a.kingdom.troups_number >kingdom_node_b.kingdom.troups_number) 
		
		for own_kingdom in own_kingdoms:
			var max_distance_castle=-1
			var max_distance_path_missive=[];
			var max_distance_path=[]
			var shortest_neutral_path_missive=[]
			var shortest_neutral_path=[]
			var neutral_case_minimun_distance = 100000000
			var shortest_ennemy_path_missive=[]
			var shortest_ennemy_path=[]
			var enemy_case_minimun_distance = 100000000
			
			var random_sort_kingdoms = kingdoms.duplicate()
			random_sort_kingdoms.shuffle()
			for kingdom_node in random_sort_kingdoms:
				if kingdom_node.kingdom.owner_index == owner_index:
					continue

				var roadsFoundMissive = find_shortest_path(castle,own_kingdom,owner_index, 0, [],1000000000, [])

				if roadsFoundMissive.size() == 0:
					continue
					
				var roadsFound = find_shortest_path(own_kingdom,kingdom_node,owner_index, 0, [],1000000000, [])
				if roadsFound.size() == 0:
					continue

				if roadsFound.size() > 0:
					possible_path.append(roadsFound)
					var distance = roadsFound.size() + roadsFoundMissive.size()
					if distance > max_distance_castle:
						max_distance_castle = distance
						max_distance_path = roadsFound
						max_distance_path_missive = roadsFoundMissive
					if kingdom_node.kingdom.owner_index == -1:
						if neutral_case_minimun_distance < distance:
							shortest_neutral_path_missive = roadsFoundMissive
							neutral_case_minimun_distance = distance
							shortest_neutral_path = roadsFound
					if kingdom_node.kingdom.owner_index == 0:
						if enemy_case_minimun_distance < distance:
							shortest_ennemy_path_missive = roadsFoundMissive
							enemy_case_minimun_distance = distance
							shortest_ennemy_path = roadsFound

				if enemy_case_minimun_distance < neutral_case_minimun_distance:
					send_missive(castle,shortest_ennemy_path_missive[shortest_ennemy_path_missive.size() - 1],shortest_ennemy_path_missive,shortest_ennemy_path,owner_index)
					return
				elif neutral_case_minimun_distance < 100000000:
					send_missive(castle,shortest_neutral_path_missive[shortest_neutral_path_missive.size() - 1],shortest_neutral_path_missive,shortest_neutral_path,owner_index)
					return
				else:
					send_missive(castle,max_distance_path_missive[max_distance_path_missive.size() - 1],max_distance_path_missive,max_distance_path,owner_index)
					return

func find_shortest_path(kingdom_node_departure: KingdomNode,kingdom_node_destination: KingdomNode, owner_index:int, distance:int, kingdom_path_took:Array, shortest_distance_found:int,road_took:Array) -> Array:
	var roadsNodes: Array = kingdom_node_departure.roads_to_neighbours
	var roadsFound: Array = [] 
	for roadNode in roadsNodes:
		var kingdom_neighbour = roadNode.kingdom_a
		if kingdom_neighbour == kingdom_node_departure:
			kingdom_neighbour = roadNode.kingdom_b

		if road_took.has(roadNode):
			continue
	
		var new_road_took = road_took.duplicate()
		new_road_took.append(roadNode)

		var new_kingdom_path_took = kingdom_path_took.duplicate()
		new_kingdom_path_took.append(kingdom_neighbour)

		if kingdom_neighbour == kingdom_node_destination and new_kingdom_path_took.size() < shortest_distance_found:
			roadsFound = new_kingdom_path_took
			shortest_distance_found=distance+1
		else:
			if(distance+1 >= shortest_distance_found):
				continue
			if kingdom_neighbour.kingdom.owner_index != owner_index:
				continue
			
			var shortest_roads= find_shortest_path(kingdom_neighbour,kingdom_node_destination,owner_index, distance+1, new_kingdom_path_took,shortest_distance_found,new_road_took)
			if shortest_roads.size() >= shortest_distance_found or shortest_roads.size() ==0:
				continue
			roadsFound = shortest_roads
			shortest_distance_found = shortest_roads.size()

	return roadsFound

func get_neighbour_road(kingdom_node_a:KingdomNode, kingdom_node_b:KingdomNode) -> Array:
	var index = kingdom_node_a.roads_to_neighbours.find(func(road):
		return (road.kingdom_a == kingdom_node_a and road.kingdom_b == kingdom_node_b) or (road.kingdom_a == kingdom_node_b and road.kingdom_b == kingdom_node_a)
		)
	if( index >= 0):
		return kingdom_node_a.roads_to_neighbours[index]
	return []

func get_neighbours(kingdom_node: KingdomNode) -> Array:
	return kingdom_node.neighbours

func get_next_kingdom(previous_kingdom: KingdomNode,road: RoadNode):
	if road.kingdom_a ==previous_kingdom:
		return road.kingdom_node_b
	return road.kingdom_a

func calculate_kingdom_path(kingdom_node_departure: KingdomNode,road_path: Array):
	var kingdom_path =[kingdom_node_departure]
	var previous_kingdom = kingdom_node_departure
	for road in road_path:
		previous_kingdom =get_next_kingdom(previous_kingdom, road)
		kingdom_path.append(previous_kingdom)
	return kingdom_path

func send_troup(kingdom_node_departure: KingdomNode,kingdom_node_destination: KingdomNode,road_path: Array,owner_index:int) -> void:
	print("send_troup"+ str(owner_index))
	var pos = kingdom_node_departure.global_position
	var _dest = kingdom_node_destination.global_position
	var troups_scene = TroupsHandlerNode.new()
	var troups_definition = TroupsDefinitionResource.new()
	troups_scene.troups = troups_definition
	troups_scene.troups.owner_index = owner_index
	troups_scene.troups.quantity=ceili(kingdom_node_departure.kingdom.troups_number / 2.0)
	troups_scene.troups.kingdom_departure=kingdom_node_departure
	troups_scene.troups.kingdom_destination=kingdom_node_destination
	troups_scene.troups.road_path = road_path
	troups_scene.global_position = pos
	add_handler(troups_scene)


func send_missive(kingdom_node_departure: KingdomNode,kingdom_node_destination: KingdomNode,road_path_missive: Array,road_path_troops: Array,owner_index:int) -> void:
	print("send_missive"+ str(owner_index))
	var pos = kingdom_node_departure.global_position
	var _dest = kingdom_node_destination.global_position
	var troups_scene = MissiveHandlerNode.new()
	var troups_definition = TroupsDefinitionResource.new()
	troups_scene.troups = troups_definition
	troups_scene.troups.owner_index = owner_index
	troups_scene.troups.quantity=1
	troups_scene.troups.kingdom_departure=kingdom_node_departure
	troups_scene.troups.kingdom_destination=kingdom_node_destination
	troups_scene.troups.road_path = road_path_missive
	troups_scene.road_path_troops = road_path_troops
	troups_scene.global_position = pos
	add_handler(troups_scene)

func add_handler(troups_scene):
	print("add_handler troups_scene" + str(troups_scene))
	if not troups_scene and troups_scene.is_queued_for_deletion():
		printerr("Error,add_handler is_queued_for_deletion")
		return 

	add_child(troups_scene)
	handler_nodes.append(troups_scene)
	troups_scene.finish_turn.connect(on_handler_finish_turn)
	troups_scene.handler_free.connect(on_handler_free)
	troups_scene.handler_added.connect(on_handler_added)

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
	print("is_turn_finished"+str(is_turn_finished))
	if is_turn_finished:
		handler_nodes_finished = []
		for handler in handler_nodes_next_round:
			add_handler(handler)
		handler_nodes_next_round = []
		GameManager.end_turn()
	check_game_finished()
		
	
func check_game_finished() -> bool:
	if kingdoms[0].kingdom.owner_index == 1:
		GameManager.end_game(1)
		return true
	if  kingdoms[kingdoms.size()-1].kingdom.owner_index == 0 :
		GameManager.end_game(0)
		return true
	return false
	  
