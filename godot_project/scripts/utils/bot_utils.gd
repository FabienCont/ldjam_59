class_name BotUtils

static func get_command_ia(kingdoms:Array[KingdomDefinitionResource], castle_ia:KingdomDefinitionResource, ia_owner_index:int) -> BaseCommandResource:
	var possible_path = []
	if castle_ia.troups_number>5:
		var max_distance_castle=-1
		var max_distance_path=[]
		var shortest_neutral_path=[]
		var neutral_case_minimun_distance = 100000000
		var shortest_ennemy_path=[]
		var enemy_case_minimun_distance = 100000000
		var random_sort_kingdoms = kingdoms.duplicate()
		random_sort_kingdoms.shuffle()
		for kingdom in random_sort_kingdoms:
			if kingdom.owner_index == ia_owner_index:
				continue
			var roadsFound = KingdomsPathSolver.get_shortest_path(castle_ia,kingdom,ia_owner_index)
			if roadsFound.size() > 0:
				possible_path.append(roadsFound)
				if roadsFound.size() > max_distance_castle:
					max_distance_castle = roadsFound.size() 
					max_distance_path = roadsFound
				if kingdom.owner_index == -1:
					if neutral_case_minimun_distance < roadsFound.size():
						neutral_case_minimun_distance = roadsFound.size()
						shortest_neutral_path = roadsFound
				if kingdom.owner_index == 0:
					if enemy_case_minimun_distance < roadsFound.size():
						enemy_case_minimun_distance = roadsFound.size()
						shortest_ennemy_path = roadsFound
			
		if enemy_case_minimun_distance < neutral_case_minimun_distance:
			return SoldierCommandResource.new(castle_ia,shortest_ennemy_path[shortest_ennemy_path.size() - 1],ia_owner_index,shortest_ennemy_path)
		elif neutral_case_minimun_distance < 100000000:
			return SoldierCommandResource.new(castle_ia,shortest_neutral_path[shortest_neutral_path.size() - 1],ia_owner_index,shortest_neutral_path)
		else:
			return SoldierCommandResource.new(castle_ia,max_distance_path[max_distance_path.size() - 1],ia_owner_index,max_distance_path)

	else:
		var own_kingdoms = kingdoms.filter(func(kingdom_node):return kingdom_node.owner_index == ia_owner_index)
		if own_kingdoms.size() == 0:
			return
	
		own_kingdoms.sort_custom(func(kingdom_node_a,kingdom_node_b): return kingdom_node_a.troups_number >kingdom_node_b.troups_number) 
		
		for own_kingdom in own_kingdoms:
			var max_distance_castle=-1
			var max_distance_path_missive=[]
			var max_distance_path=[]
			var shortest_neutral_path_missive=[]
			var shortest_neutral_path=[]
			var neutral_case_minimun_distance = 100000000
			var shortest_ennemy_path_missive=[]
			var shortest_ennemy_path=[]
			var enemy_case_minimun_distance = 100000000
			
			var random_sort_kingdoms = kingdoms.duplicate()
			random_sort_kingdoms.shuffle()
			for kingdom in random_sort_kingdoms:
				if kingdom.owner_index == ia_owner_index:
					continue

				var roadsFoundMissive = KingdomsPathSolver.get_shortest_path(castle_ia,own_kingdom,ia_owner_index)

				if roadsFoundMissive.size() < 2:
					continue
					
				var roadsFound = KingdomsPathSolver.get_shortest_path(own_kingdom,kingdom,ia_owner_index)
				if roadsFound.size() < 2:
					continue

				possible_path.append(roadsFound)
				var distance = roadsFound.size() + roadsFoundMissive.size()
				if distance > max_distance_castle:
					max_distance_castle = distance
					max_distance_path = roadsFound
					max_distance_path_missive = roadsFoundMissive
				if kingdom.owner_index == -1:
					if neutral_case_minimun_distance < distance:
						shortest_neutral_path_missive = roadsFoundMissive
						neutral_case_minimun_distance = distance
						shortest_neutral_path = roadsFound
				if kingdom.owner_index == 0:
					if enemy_case_minimun_distance < distance:
						shortest_ennemy_path_missive = roadsFoundMissive
						enemy_case_minimun_distance = distance
						shortest_ennemy_path = roadsFound

				if enemy_case_minimun_distance < neutral_case_minimun_distance:
					return MissiveCommandResource.new(castle_ia,shortest_ennemy_path[shortest_ennemy_path.size() - 1],ia_owner_index,shortest_ennemy_path_missive,shortest_ennemy_path)
				elif neutral_case_minimun_distance < 100000000:
					return MissiveCommandResource.new(castle_ia,shortest_neutral_path[shortest_neutral_path.size() - 1],ia_owner_index,shortest_neutral_path_missive,shortest_neutral_path)
				else:
					return MissiveCommandResource.new(castle_ia,max_distance_path_missive[max_distance_path_missive.size() - 1],ia_owner_index,max_distance_path_missive,max_distance_path)
		return