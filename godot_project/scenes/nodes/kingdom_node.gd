class_name KingdomNode
extends Node2D

enum HighlightState { NONE, HIGHLIGHT, HIGHLIGHT_ARRIVED, SELECTED }

signal kingdom_selected(kingdom: KingdomNode)
signal kingdom_hovered(kingdom: KingdomNode)
signal kingdom_unhovered(kingdom: KingdomNode)

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_focus: Sprite2D = $Sprite2DFocus
@onready var flag: FlagNode = $FlagNode
@export var collisionArea2D: Area2D
@export var inputArea2D: Area2D
@onready var label: Label = $Label
@onready var tween: Tween = null

@export var force_unit_number: int = -1

@export var kingdom: KingdomDefinitionResource = KingdomDefinitionResource.new():
	set= set_kingdom;

@onready var highlight_state: HighlightState = HighlightState.NONE:
	set(value):
		highlight_state = value
		if tween:
			tween.kill()
		match value:
			HighlightState.NONE:
				sprite_focus.visible = false
				sprite_focus.modulate.a = 1.0
				tween = create_tween().bind_node(self)
				tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5)
				tween.set_ease(Tween.EASE_IN)
				tween.set_trans(Tween.TRANS_SINE)
			HighlightState.HIGHLIGHT:
				sprite_focus.visible = true
				sprite_focus.modulate.a = 0.4
			HighlightState.HIGHLIGHT_ARRIVED:
				sprite_focus.visible = true
				sprite_focus.modulate.a = 0.75
				tween = create_tween().bind_node(self)
				tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.25)
				tween.set_ease(Tween.EASE_IN)
				tween.set_trans(Tween.TRANS_BOUNCE)
			HighlightState.SELECTED:
				sprite_focus.visible = true
				sprite_focus.modulate.a = 1.0
				tween = create_tween().bind_node(self)
				tween.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.25)
				tween.set_ease(Tween.EASE_IN)
				tween.set_trans(Tween.TRANS_BOUNCE)

func set_kingdom(value: KingdomDefinitionResource) -> void:
	kingdom = value
	kingdom.kingdomNode = self
	kingdom.kingdom_owner_changed.connect(_on_kingdom_owner_changed)
	kingdom.kingdom_troups_changed.connect(_on_kingdom_troups_changed)
	kingdom.kingdom_is_castle_changed.connect(_on_kingdom_is_castle_changed)
	update_texture()

func update_texture():
	if kingdom.is_castle == true:
		sprite.texture = load("res://assets/sprites/castle_01.aseprite")
	else:
		sprite.texture = load("res://assets/sprites/village_01.aseprite")

func _ready() -> void:
	inputArea2D.mouse_entered.connect(onmouse_entered)
	inputArea2D.mouse_exited.connect(onmouse_exited)
	inputArea2D.input_event.connect(on_area_2d_input_event)
	collisionArea2D.area_entered.connect(on_area_entered)
	if(kingdom):
		kingdom.kingdom_owner_changed.connect(_on_kingdom_owner_changed)
		kingdom.kingdom_troups_changed.connect(_on_kingdom_troups_changed)
		kingdom.kingdom_is_castle_changed.connect(_on_kingdom_is_castle_changed)
		update_texture()
		flag.owner_index = kingdom.owner_index


func _on_kingdom_owner_changed() -> void:
	flag.owner_index = kingdom.owner_index

func _on_kingdom_is_castle_changed() -> void:
	update_texture()

func _on_kingdom_troups_changed() -> void:
	label.text = str(kingdom.troups_number)

func onmouse_entered() -> void:
	if highlight_state == HighlightState.SELECTED:
		return
	emit_signal("kingdom_hovered", self)

func onmouse_exited() -> void:
	if highlight_state == HighlightState.SELECTED:
		return
	emit_signal("kingdom_unhovered", self)

func select_kingdom():
	kingdom_selected.emit(self)

func on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		select_kingdom()

func on_area_entered(area: Area2D) -> void:
	var unit = area.get_parent()
	if unit is SoldierNode:
		if unit.troupsOrigin.road_path_soldier[unit.troupsOrigin.step+1].kingdomNode != self:
			return
		soldier_arrived(unit)
	elif unit is MissiveNode:
		if unit.troupsOrigin.road_path_missive[unit.troupsOrigin.step+1].kingdomNode != self:
			return
		missive_arrived(unit)
		
func soldier_arrived(soldier_node: SoldierNode) -> void:
	var soldierTroupsOrigin = soldier_node.troupsOrigin
	if kingdom.owner_index == -1:
		kingdom.owner_index =soldierTroupsOrigin.owner_index
		kingdom.troups_number+=1
		soldier_node.arrive()
	elif kingdom.owner_index == soldierTroupsOrigin.owner_index:
		kingdom.troups_number+=1
		soldier_node.arrive()
	else:
		if(kingdom.troups_number <= 0):
			kingdom.troups_number=1
			kingdom.owner_index = soldierTroupsOrigin.owner_index
			soldier_node.arrive()
		else:
			kingdom.troups_number-=1
			soldier_node.die()

func missive_arrived(missive_node: MissiveNode) -> void:
	var missiveTroupsOrigin = missive_node.troupsOrigin
	if kingdom.owner_index == -1:
		kingdom.owner_index = missiveTroupsOrigin.owner_index
		kingdom.troups_number += 1
		missive_node.arrive()
	elif kingdom.owner_index == missiveTroupsOrigin.owner_index:
		kingdom.troups_number+=1
		missive_node.arrive()
	else:
		if(kingdom.troups_number <= 0):
			kingdom.troups_number=1
			kingdom.owner_index = missiveTroupsOrigin.owner_index
			missive_node.arrive()
		else:
			missive_node.die()
