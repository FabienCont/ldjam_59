class_name IncomingUnitsController
extends RefCounted

const INCOMING_ICON_SCENE = preload("res://scenes/nodes/IncomingUnitIcon.tscn")
const SOLDIER_TEXTURE = preload("res://assets/sprites/icon_soldier_16x16.aseprite")
const MISSIVE_TEXTURE = preload("res://assets/sprites/icon_missive_16x16.aseprite")

var _turn_controller: TurnController
var _icons: Array = []
var _pending_preview: PendingMovePreview = PendingMovePreview.new()

func setup(turn_controller: TurnController) -> void:
	_turn_controller = turn_controller
	GameManager.turn_ended.connect(refresh)
	GameManager.level_finished.connect(clear)

func refresh() -> void:
	if GameManager.game_state == GameManager.GameState.FINISH:
		return
	clear()
	var kingdoms_stack: Dictionary = {}
	for handler in _turn_controller.handler_nodes:
		if handler.troups.owner_index != GameManager.indexPlayer:
			continue
		var destination_kingdom: KingdomNode = null
		var is_missive: bool = false
		var quantity: int = 0
		if handler is SoldierHandlerNode:
			destination_kingdom = get_interest_kingdom(handler.troups).kingdomNode
			quantity = handler.troups.quantity
		elif handler is MissiveHandlerNode:
			var kingdom_definition = get_interest_kingdom(handler.troups)
			destination_kingdom = kingdom_definition.kingdomNode
			quantity = ceili(kingdom_definition.troups_number / 2.0)
			is_missive = true
		if destination_kingdom == null:
			continue
		var stack_index: int = kingdoms_stack.get(destination_kingdom, 0)
		_add_icon(destination_kingdom, is_missive, quantity, stack_index, handler)
		kingdoms_stack[destination_kingdom] = stack_index + 1

func get_intestest_kingdom_node_old(troups) -> KingdomNode:
	return troups.road_path_soldier.back().kingdomNode

func get_interest_kingdom(troups) -> KingdomDefinitionResource:
	return troups.road_path_soldier[troups.step-1]

func _add_icon(kingdom_node: KingdomNode, is_missive: bool, quantity: int, stack_index: int, handler: Node) -> void:
	var icon: IncomingUnitIcon = INCOMING_ICON_SCENE.instantiate()
	kingdom_node.add_child(icon)
	icon.position = Vector2(-10.0 + stack_index * 24.0, 30.0)
	icon.texture = MISSIVE_TEXTURE if is_missive else SOLDIER_TEXTURE
	icon.quantity_label.text = str(quantity)
	icon.turn_label.text = str(turns_to_arrival(handler))
	icon.handler = handler
	icon.icon_hovered.connect(_on_icon_hovered)
	icon.icon_unhovered.connect(_on_icon_unhovered)
	_icons.append(icon)

func _on_icon_hovered(icon: IncomingUnitIcon) -> void:
	if not is_instance_valid(icon.handler):
		return
	_pending_preview.show_handler(icon.handler)

func _on_icon_unhovered(_icon: IncomingUnitIcon) -> void:
	_pending_preview.hide()

func turns_to_arrival(handler: Node) -> int:
	if handler is SoldierHandlerNode:
		return max(0, handler.troups.road_path_soldier.size() - handler.troups.step - 1) -1
	elif handler is MissiveHandlerNode:
		return max(0, handler.troups.road_path_missive.size() - handler.troups.step - 1) + max(0, handler.troups.road_path_soldier.size() - handler.troups.step - 1) -1
	return 0
	
func clear() -> void:
	_pending_preview.hide()
	for icon in _icons:
		if is_instance_valid(icon) and not icon.is_queued_for_deletion():
			icon.queue_free()
	_icons.clear()
