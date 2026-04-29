class_name LevelNode
extends Node2D

@onready var kingdoms_node: Node2D = $Kingdoms
@onready var roads_node: Node2D = $Roads
@onready var indexPlayer:int = 0
var highlight_controller := HighlightController.new()

var preview_play: PreviewPlay = PreviewPlay.new()
var _click_consumed_by_kingdom := false

func _ready() -> void:
	LevelInitUtils.init_kingdoms(kingdoms_node, roads_node)
	for kingdoms_child_node in kingdoms_node.get_children():
		if not kingdoms_child_node is KingdomNode:
			continue
		kingdoms_child_node.kingdom_selected.connect(select_kingdom)
		kingdoms_child_node.kingdom_hovered.connect(on_kingdom_hovered)
		kingdoms_child_node.kingdom_unhovered.connect(on_kingdom_unhovered)
	highlight_controller.setup(preview_play, self)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_consumed_by_kingdom = false
		call_deferred("_on_click_deferred")

func _on_click_deferred() -> void:
	if not _click_consumed_by_kingdom:
		highlight_controller.reset_highlight()

func on_kingdom_hovered(kingdom_node: KingdomNode) -> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	if not highlight_controller.kingdom_selected and kingdom_node.kingdom.owner_index == indexPlayer:
		kingdom_node.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
		highlight_controller.kingdomHighlighted.append(kingdom_node)
		return
	if not highlight_controller.kingdom_selected:
		return

	var shortest_command = KingdomsPathSolver.get_shortest_command(GameManager.kingdoms[0],highlight_controller.kingdom_selected.kingdom,kingdom_node.kingdom,indexPlayer)
	if not shortest_command:
		return
	highlight_controller.hovered_command = shortest_command

func on_kingdom_unhovered(kingdom_node: KingdomNode) -> void:
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
	if highlight_controller.kingdom_selected == kingdom_node:
		return
	highlight_controller.reset_highlight_except_selected()

func select_kingdom(kingdom_node: KingdomNode)-> void:
	_click_consumed_by_kingdom = true
	if GameManager.turn_state ==GameManager.TurnState.PLAYING or GameManager.game_state == GameManager.GameState.FINISH :
		return
		
	if highlight_controller.kingdom_selected == kingdom_node:
		highlight_controller.reset_highlight()
		return

	if highlight_controller.kingdom_selected == null and kingdom_node.kingdom.owner_index == indexPlayer:
		highlight_controller.kingdom_selected = kingdom_node
		kingdom_node.highlight_state = KingdomNode.HighlightState.SELECTED
		return

	elif highlight_controller.kingdom_selected != null and kingdom_node != highlight_controller.kingdom_selected:
		var shortest_command = KingdomsPathSolver.get_shortest_command(GameManager.kingdoms[0],highlight_controller.kingdom_selected.kingdom,kingdom_node.kingdom,indexPlayer)
		if not shortest_command:
			highlight_controller.reset_highlight()
			return
		GameManager.play_command(shortest_command)
		highlight_controller.reset_highlight()
