class_name KingdomDefinitionResource
extends Resource

signal kingdom_troups_changed
signal kingdom_owner_changed
signal kingdom_is_castle_changed

var neighbours: Array = [];
var roads_to_neighbours: Array = [];

var is_castle: bool=false:
    set(value):
        is_castle = value
        emit_signal("kingdom_is_castle_changed")

var owner_index: int  = -1:
    set(value):
        owner_index = value
        emit_signal("kingdom_owner_changed")

var troups_number: int = 10:
    set(value):
        troups_number = value
        emit_signal("kingdom_troups_changed")

var kingdomNode: KingdomNode = null