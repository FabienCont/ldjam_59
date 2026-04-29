class_name LevelNode
extends Node2D

@onready var kingdoms_node: Node2D = $Kingdoms
@onready var roads_node: Node2D = $Roads
@onready var indexPlayer:int = 0
@onready var kingdom_selected:KingdomNode = null
@onready var kingdomHighlighted:Array[KingdomNode] = []
@onready var highlight_path_missive = []:
	set= set_highlight_path_missive
@onready var highlight_path_soldier = []:
	set= set_highlight_path_soldier

var preview_play: PreviewPlay = PreviewPlay.new()
var _click_consumed_by_kingdom := false

var hovered_command: BaseCommandResource = null:
	set = set_hovered_command

func _ready() -> void:
	var dicoKingdomNeighbours: Dictionary[Node,Array] = {}
	var dicoKingdomNeighboursRoads: Dictionary[Node,Array] = {}

	var roads = roads_node.get_children().filter(func(child): return child is RoadNode);
	for road_node in roads:
		if not dicoKingdomNeighbours.has(road_node.kingdom_a):
			dicoKingdomNeighbours[road_node.kingdom_a] =[]
		if not dicoKingdomNeighbours.has(road_node.kingdom_b):
			dicoKingdomNeighbours[road_node.kingdom_b] =[]
		if not dicoKingdomNeighboursRoads.has(road_node.kingdom_a):
			dicoKingdomNeighboursRoads[road_node.kingdom_a] =[]
		if not dicoKingdomNeighboursRoads.has(road_node.kingdom_b):
			dicoKingdomNeighboursRoads[road_node.kingdom_b] =[]

		dicoKingdomNeighboursRoads[road_node.kingdom_a].append(road_node.road)
		dicoKingdomNeighboursRoads[road_node.kingdom_b].append(road_node.road)
		dicoKingdomNeighbours[road_node.kingdom_a].append(road_node.kingdom_b)
		dicoKingdomNeighbours[road_node.kingdom_b].append(road_node.kingdom_a)

	var kingdoms_children = kingdoms_node.get_children()
	for index in range(kingdoms_children.size()):
		var kingdoms_child_node = kingdoms_children[index]
		if not kingdoms_child_node is KingdomNode:
			continue
		
		var troups_number:int = 20
		if kingdoms_child_node.force_unit_number != -1:
			troups_number = kingdoms_child_node.force_unit_number
		if (index == 0):
			set_kingdom_info(kingdoms_child_node, true, 0, troups_number,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		elif index == kingdoms_children.size() - 1:
			set_kingdom_info(kingdoms_child_node, true, 1, troups_number,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		else:
			set_kingdom_info(kingdoms_child_node, false,-1, troups_number,dicoKingdomNeighbours[kingdoms_child_node], dicoKingdomNeighboursRoads[kingdoms_child_node])
		GameManager.kingdoms.append(kingdoms_child_node.kingdom)
		kingdoms_child_node.kingdom_selected.connect(select_kingdom)
		kingdoms_child_node.kingdom_hovered.connect(on_kingdom_hovered)
		kingdoms_child_node.kingdom_unhovered.connect(on_kingdom_unhovered)

func set_kingdom_info(kingdom_node: KingdomNode, is_castle: bool, owner_index: int, troups_number: int, neighbours: Array, neighboursRoads: Array) -> void:
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


func set_hovered_command(value: BaseCommandResource) -> void:
	hovered_command = value
	highlight_path_soldier = []
	highlight_path_missive = []
	preview_play.stop()
	if not value:
		return
	if value.road_path_soldier:
		highlight_path_soldier = value.road_path_soldier
	if value is MissiveCommandResource and value.road_path_missive:
		highlight_path_missive = value.road_path_missive
	preview_play.play(value, self)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_consumed_by_kingdom = false
		call_deferred("_on_click_deferred")

func _on_click_deferred() -> void:
	if not _click_consumed_by_kingdom:
		reset_highlight()

func reset_highlight():
	for kingdom in kingdomHighlighted:
		kingdom.highlight_state = KingdomNode.HighlightState.NONE
	kingdomHighlighted = []
	hovered_command = null
	if kingdom_selected:
		kingdom_selected.highlight_state = KingdomNode.HighlightState.NONE
		kingdom_selected = null
		
func set_highlight_path_soldier(value):
	highlight_path_soldier = value
	for kingdom in highlight_path_soldier:
		if kingdom.kingdomNode == kingdom_selected:
			continue
		if kingdom.kingdomNode not in kingdomHighlighted:
			kingdom.kingdomNode.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
			kingdomHighlighted.append(kingdom.kingdomNode)

func set_highlight_path_missive(value):
	highlight_path_missive = value
	for kingdom in highlight_path_missive:
		if kingdom.kingdomNode == kingdom_selected:
			continue
		if kingdom.kingdomNode not in kingdomHighlighted:
			kingdom.kingdomNode.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
			kingdomHighlighted.append(kingdom.kingdomNode)

func reset_highlight_except_selected():
	for kingdom in kingdomHighlighted:
		if kingdom != kingdom_selected:
			kingdom.highlight_state = KingdomNode.HighlightState.NONE
	kingdomHighlighted = []
	hovered_command = null

func on_kingdom_hovered(kingdom_node: KingdomNode) -> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	if not kingdom_selected and kingdom_node.kingdom.owner_index == indexPlayer:
		kingdom_node.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
		kingdomHighlighted.append(kingdom_node)
		return
	if not kingdom_selected:
		return

	var shortest_command = KingdomsPathSolver.get_shortest_command(GameManager.kingdoms[0],kingdom_selected.kingdom,kingdom_node.kingdom,indexPlayer)
	if not shortest_command:
		return
	hovered_command = shortest_command

func on_kingdom_unhovered(kingdom_node: KingdomNode) -> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	if kingdom_selected == kingdom_node:
		return
	reset_highlight_except_selected()

func select_kingdom(kingdom_node: KingdomNode)-> void:
	_click_consumed_by_kingdom = true
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
		
	if kingdom_selected == kingdom_node:
		reset_highlight()
		return

	if kingdom_selected == null and kingdom_node.kingdom.owner_index == indexPlayer:
		kingdom_selected = kingdom_node
		kingdom_node.highlight_state = KingdomNode.HighlightState.SELECTED
		return

	elif kingdom_selected != null and kingdom_node != kingdom_selected:
		var shortest_command = KingdomsPathSolver.get_shortest_command(GameManager.kingdoms[0],kingdom_selected.kingdom,kingdom_node.kingdom,indexPlayer)
		print("shortest_command"+str(shortest_command))
		if not shortest_command:
			reset_highlight()
			return
		GameManager.play_command(shortest_command)
		reset_highlight()
