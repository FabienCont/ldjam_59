@tool
class_name RoadNode
extends Node2D

var road: RoadDefinitionResource = RoadDefinitionResource.new() 

@export var kingdom_a: KingdomNode:
    set=set_kingdom_a

@export var kingdom_b: KingdomNode:
    set= set_kingdom_b

func set_kingdom_a(value:KingdomNode) -> void:
    if(value != kingdom_b or value == null):
        kingdom_a = value

func set_kingdom_b(value:KingdomNode) -> void:
    if(value != kingdom_a or value == null):
        kingdom_b = value

func _draw() -> void:
    if Engine.is_editor_hint():
        draw_line_between_kingdom()

func draw_line_between_kingdom() -> void:
    if kingdom_a != null and kingdom_b != null:
        draw_line(kingdom_a.global_position,kingdom_b.global_position, Color.from_rgba8(255,0,0,255),10)
    pass