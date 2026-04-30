class_name MissiveTroupsResource
extends TroupsDefinitionResource

var road_path_soldier:Array
var road_path_missive:Array

func _init (p_kingdom_departure: KingdomDefinitionResource, p_kingdom_destination: KingdomDefinitionResource, p_owner_index: int, p_quantity: int, p_road_path_soldier: Array, p_road_path_missive: Array, p_step: int = 0) -> void:
    kingdom_departure = p_kingdom_departure
    kingdom_destination = p_kingdom_destination
    owner_index = p_owner_index
    quantity = p_quantity
    road_path_soldier = p_road_path_soldier
    road_path_missive = p_road_path_missive
    step = p_step