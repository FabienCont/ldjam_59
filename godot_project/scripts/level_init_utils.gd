class_name LevelInitUtils

static func init_kingdoms(kingdoms_node: Node2D, roads_node: Node2D) -> void:
	var dicoKingdomNeighbours: Dictionary[Node, Array] = {}
	var dicoKingdomNeighboursRoads: Dictionary[Node, Array] = {}

	var roads = roads_node.get_children().filter(func(child): return child is RoadNode)
	for road_node in roads:
		if not dicoKingdomNeighbours.has(road_node.kingdom_a):
			dicoKingdomNeighbours[road_node.kingdom_a] = []
		if not dicoKingdomNeighbours.has(road_node.kingdom_b):
			dicoKingdomNeighbours[road_node.kingdom_b] = []
		if not dicoKingdomNeighboursRoads.has(road_node.kingdom_a):
			dicoKingdomNeighboursRoads[road_node.kingdom_a] = []
		if not dicoKingdomNeighboursRoads.has(road_node.kingdom_b):
			dicoKingdomNeighboursRoads[road_node.kingdom_b] = []

		dicoKingdomNeighboursRoads[road_node.kingdom_a].append(road_node.road)
		dicoKingdomNeighboursRoads[road_node.kingdom_b].append(road_node.road)
		dicoKingdomNeighbours[road_node.kingdom_a].append(road_node.kingdom_b)
		dicoKingdomNeighbours[road_node.kingdom_b].append(road_node.kingdom_a)

	var kingdoms_children = kingdoms_node.get_children()
	for index in range(kingdoms_children.size()):
		var kingdoms_child_node = kingdoms_children[index]
		if not kingdoms_child_node is KingdomNode:
			continue

		var troups_number: int = 20
		if kingdoms_child_node.force_unit_number != -1:
			troups_number = kingdoms_child_node.force_unit_number
		if index == 0:
			_set_kingdom_info(kingdoms_child_node, true, 0, troups_number, dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		elif index == kingdoms_children.size() - 1:
			_set_kingdom_info(kingdoms_child_node, true, 1, troups_number, dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		else:
			_set_kingdom_info(kingdoms_child_node, false, -1, troups_number, dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		GameManager.kingdoms.append(kingdoms_child_node.kingdom)


static func _set_kingdom_info(kingdom_node: KingdomNode, is_castle: bool, owner_index: int, troups_number: int, neighbours: Array, neighboursRoads: Array) -> void:
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
