class_name SoldierTroupsResource
extends TroupsDefinitionResource

var road_path_soldier: Array
var road_path_missive: Array = []

func _init (p_kingdom_departure: KingdomDefinitionResource, p_kingdom_destination: KingdomDefinitionResource, p_owner_index: int, p_quantity: int, p_road_path_soldier: Array, p_step: int = -1) -> void:
    kingdom_departure = p_kingdom_departure
    kingdom_destination = p_kingdom_destination
    owner_index = p_owner_index
    quantity = p_quantity
    road_path_soldier = p_road_path_soldier
    step = p_step