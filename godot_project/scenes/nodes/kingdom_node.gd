class_name KingdomNode
extends Node2D

signal kingdom_selected(kingdom: KingdomNode)

@onready var sprite: Sprite2D = $Sprite2D
@onready var flag: FlagNode = $FlagNode
@onready var area2D: Area2D = $Area2D
@onready var colorRect: ColorRect = $ColorRect
@onready var label: Label = $Label
@onready var neighbours: Array = [];
@onready var roads_to_neighbours: Array = [];
@onready var tween

@export var force_unit_number: int = -1

@export var kingdom: KingdomDefinitionResource:
	set= set_kingdom;

@onready var selected: bool = false:
	set(value):
		selected = value
		print("apply selected" + str(kingdom)+" "+ str(value))
		if(value == true):
			if tween:
				tween.kill() 
				tween = create_tween().bind_node(self)
				tween.tween_property(sprite, "scale", Vector2(1.25,1.25), 0.25)
				tween.set_ease(Tween.TRANS_BOUNCE)
		else:
			if tween:
				tween.kill() 
				tween = create_tween().bind_node(self)
				tween.tween_property(sprite, "scale", Vector2(1.0,1.0), 0.5)
				tween.set_ease(Tween.TRANS_SINE)

func set_kingdom(value: KingdomDefinitionResource) -> void:
	kingdom = value
	kingdom.kingdom_owner_changed.connect(_on_kingdom_owner_changed)
	kingdom.kingdom_troups_changed.connect(_on_kingdom_troups_changed)
	kingdom.kingdom_is_castle_changed.connect(_on_kingdom_is_castle_changed)
	if kingdom.is_castle == true:
		sprite.texture = load("res://assets/sprites/castle_01.aseprite")

func _ready() -> void:
	area2D.mouse_entered.connect(onmouse_entered)
	area2D.mouse_exited.connect(onmouse_exited)
	area2D.input_event.connect(on_area_2d_input_event)
	if(kingdom):
		kingdom.kingdom_owner_changed.connect(_on_kingdom_owner_changed)
		kingdom.kingdom_troups_changed.connect(_on_kingdom_troups_changed)
		if kingdom.is_castle == true:
			sprite.texture = load("res://assets/sprites/castle_01.aseprite")
		flag.owner_index = kingdom.owner_index


func _on_kingdom_owner_changed() -> void:
	flag.owner_index = kingdom.owner_index
	if (kingdom.owner_index == 0):
		colorRect.color = Color(0, 0, 1, 1)
	elif (kingdom.owner_index == 1):
		colorRect.color = Color(1, 0, 0, 1)
	elif (kingdom.owner_index == -1):
		colorRect.color = Color.from_rgba8(75, 85, 81, 255)
	else:
		colorRect.color = Color(0, 1, 0, 1)
	
	print("kingdom owner changed to " + str(kingdom.owner_index))

func _on_kingdom_is_castle_changed() -> void:
	if kingdom.is_castle == true:
			sprite.texture = load("res://assets/sprites/castle_01.aseprite")

func _on_kingdom_troups_changed() -> void:
	label.text = str(kingdom.troups_number)

func onmouse_entered() -> void:
	if tween:
		tween.kill() 
	tween = create_tween().bind_node(self)
	tween.tween_property(sprite, "scale", Vector2(1.2,1.2), 0.25)
	tween.set_ease(Tween.TRANS_BOUNCE)
	

func onmouse_exited() -> void:
	if selected == true:
		return
	if tween:
		tween.kill()
	tween = create_tween().bind_node(self)
	tween.tween_property(sprite, "scale", Vector2(1.0,1.0), 0.5)
	tween.set_ease(Tween.TRANS_SINE)
	
func select_kingdom():
	print("kingdom selected " + str(kingdom))
	kingdom_selected.emit(self)

func on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		select_kingdom()

func soldier_arrived(soldier_node: SoldierNode) -> void:
	var soldierTroupsOrigin = soldier_node.troupsOrigin
	if kingdom.owner_index == -1:
		kingdom.owner_index =soldierTroupsOrigin.owner_index
		kingdom.troups_number+=1
		soldier_node.arrived.emit(soldier_node)
	elif kingdom.owner_index == soldierTroupsOrigin.owner_index:
		kingdom.troups_number+=1
		soldier_node.arrived.emit(soldier_node)
	else:
		if(kingdom.troups_number <= 0):
			kingdom.troups_number=1
			kingdom.owner_index = soldierTroupsOrigin.owner_index
		else:
			kingdom.troups_number-=1
			soldier_node.die.emit(soldier_node)

func missive_arrived(missive_node: MissiveNode) -> void:
	var missiveTroupsOrigin = missive_node.troupsOrigin
	if kingdom.owner_index == -1:
		kingdom.owner_index = missiveTroupsOrigin.owner_index
		kingdom.troups_number += 1
		missive_node.arrived.emit(missive_node)
	elif kingdom.owner_index == missiveTroupsOrigin.owner_index:
		kingdom.troups_number+=1
		missive_node.arrived.emit(missive_node)
	else:
		if(kingdom.troups_number <= 0):
			kingdom.troups_number=1
			kingdom.owner_index = missiveTroupsOrigin.owner_index
		else:
			missive_node.die.emit(missive_node)
