class_name KingdomsPathSolver

static func get_shortest_command(castle: KingdomDefinitionResource, kingdomDeparture: KingdomDefinitionResource, kingdomDestination: KingdomDefinitionResource, indexPlayer: int) -> BaseCommandResource:
	if kingdomDeparture == castle:
		var road_path = get_shortest_path(kingdomDeparture, kingdomDestination, indexPlayer)
		if road_path.size() ==0: 
			return null
		return SoldierCommandResource.new(kingdomDeparture, kingdomDestination, indexPlayer, road_path)
	else:
		var road_path_missive = get_shortest_path(castle, kingdomDeparture, indexPlayer)
		if road_path_missive.size() ==0: 
			return null
			
		var road_path_troops = get_shortest_path(kingdomDeparture, kingdomDestination, indexPlayer)
		if road_path_troops.size() ==0: 
			return null
		return  MissiveCommandResource.new(kingdomDeparture, kingdomDestination, indexPlayer, road_path_missive, road_path_troops)


static func get_shortest_path(kingdom_departure: KingdomDefinitionResource,kingdom_destination: KingdomDefinitionResource, owner_index:int) -> Array:
	var shortest_path = _find_shortest_path(kingdom_departure,kingdom_destination,owner_index, 0, [kingdom_departure],1000000000, [])
	if shortest_path.size() < 2:
		return []
	return shortest_path

static func _find_shortest_path(kingdom_departure: KingdomDefinitionResource,kingdom_destination: KingdomDefinitionResource, owner_index:int, distance:int, kingdom_path_took:Array, shortest_distance_found:int,road_took:Array) -> Array:
	var roadsNodes: Array = kingdom_departure.roads_to_neighbours
	var roadsFound: Array = [] 
	for roadNode in roadsNodes:
		var kingdom_neighbour = roadNode.kingdom_a
		if kingdom_neighbour == kingdom_departure:
			kingdom_neighbour = roadNode.kingdom_b

		if road_took.has(roadNode):
			continue
	
		var new_road_took = road_took.duplicate()
		new_road_took.append(roadNode)

		var new_kingdom_path_took = kingdom_path_took.duplicate()
		new_kingdom_path_took.append(kingdom_neighbour)

		if kingdom_neighbour == kingdom_destination and new_kingdom_path_took.size() < shortest_distance_found:
			roadsFound = new_kingdom_path_took
			shortest_distance_found=distance+1
		else:
			if(distance+1 >= shortest_distance_found):
				continue
			if kingdom_neighbour.owner_index != owner_index:
				continue
			
			var shortest_roads= _find_shortest_path(kingdom_neighbour,kingdom_destination,owner_index, distance+1, new_kingdom_path_took,shortest_distance_found,new_road_took)
			if shortest_roads.size() >= shortest_distance_found or shortest_roads.size() ==0:
				continue
			roadsFound = shortest_roads
			shortest_distance_found = shortest_roads.size()

	return roadsFound