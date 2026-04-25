class_name MissiveCommandResource
extends BaseCommandResource

var road_path_missive: Array
var road_path_soldier: Array

func _init(p_kingdom_node_departure: KingdomDefinitionResource, p_kingdom_node_destination: KingdomDefinitionResource, p_owner_index: int, p_road_path_missive: Array, p_road_path_soldier: Array) -> void:
	kingdom_node_departure = p_kingdom_node_departure
	kingdom_node_destination = p_kingdom_node_destination
	owner_index = p_owner_index
	road_path_missive = p_road_path_missive
	road_path_soldier = p_road_path_soldier