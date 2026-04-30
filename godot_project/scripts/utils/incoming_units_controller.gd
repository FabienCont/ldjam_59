class_name IncomingUnitsController
extends RefCounted

const INCOMING_ICON_SCENE = preload("res://scenes/nodes/IncomingUnitIcon.tscn")
const SOLDIER_TEXTURE = preload("res://assets/sprites/icon_soldier_16x16.aseprite")
const MISSIVE_TEXTURE = preload("res://assets/sprites/icon_missive_16x16.aseprite")

var _turn_controller: TurnController
var _icons: Array = []
var _pending_preview: PendingMovePreview = PendingMovePreview.new()
var _pinned_icon: IncomingUnitIcon = null
var icon_click_consumed: bool = false
var _command_preview_icon: IncomingUnitIcon = null
var _command_preview_play: PreviewPlay = PreviewPlay.new()

func setup(turn_controller: TurnController) -> void:
	_turn_controller = turn_controller
	GameManager.turn_ended.connect(refresh)
	GameManager.level_finished.connect(clear)

func refresh() -> void:
	if GameManager.game_state == GameManager.GameState.FINISH:
		return

	_refresh_deferred.call_deferred()

func _refresh_deferred() -> void:
	clear()
	var kingdoms_stack: Dictionary = {}
	for handler in _turn_controller.handler_nodes:
		if handler.troups.owner_index != GameManager.indexPlayer:
			continue
		var destination_kingdom: KingdomNode = null
		var is_missive: bool = false
		var quantity: int = 0
		if handler is SoldierHandlerNode:
			destination_kingdom = handler.troups.road_path_soldier.back().kingdomNode
			quantity = handler.troups.quantity
		elif handler is MissiveHandlerNode:
			destination_kingdom = handler.troups.road_path_soldier.back().kingdomNode
			quantity = ceili(handler.troups.road_path_soldier[0].troups_number / 2.0)
			is_missive = true
		if destination_kingdom == null:
			continue
		var stack_index: int = kingdoms_stack.get(destination_kingdom, 0)
		_add_icon(destination_kingdom, is_missive, quantity, stack_index, handler)
		kingdoms_stack[destination_kingdom] = stack_index + 1



func _create_icon(kingdom_node: KingdomNode, is_missive: bool, quantity: int, turns: int, stack_index: int) -> IncomingUnitIcon:
	var icon: IncomingUnitIcon = INCOMING_ICON_SCENE.instantiate()
	kingdom_node.add_child(icon)
	icon.position = Vector2(-20.0 + stack_index * 24.0, 26.0)
	icon.texture = MISSIVE_TEXTURE if is_missive else SOLDIER_TEXTURE
	icon.quantity_label.text = str(quantity)
	icon.turn_label.text = str(turns)
	return icon

func _add_icon(kingdom_node: KingdomNode, is_missive: bool, quantity: int, stack_index: int, handler: Node) -> void:
	var icon: IncomingUnitIcon = _create_icon(kingdom_node, is_missive, quantity, turns_to_arrival(handler), stack_index)
	icon.handler = handler
	icon.icon_hovered.connect(_on_icon_hovered)
	icon.icon_unhovered.connect(_on_icon_unhovered)
	icon.icon_clicked.connect(_on_icon_clicked)
	_icons.append(icon)

func _on_icon_clicked(icon: IncomingUnitIcon) -> void:
	icon_click_consumed = true
	if _pinned_icon == icon:
		_pinned_icon = null
		_pending_preview.hide()
	else:
		_pinned_icon = icon
		if is_instance_valid(icon.handler):
			_pending_preview.show_handler(icon.handler)

func _on_icon_hovered(icon: IncomingUnitIcon) -> void:
	if _pinned_icon != null:
		return
	if not is_instance_valid(icon.handler):
		return
	_pending_preview.show_handler(icon.handler)

func _on_icon_unhovered(_icon: IncomingUnitIcon) -> void:
	if _pinned_icon != null:
		return
	_pending_preview.hide()

func show_command_preview(command: BaseCommandResource, level_node: Node2D) -> void:
	hide_command_preview()
	_command_preview_play.play(command, level_node)
	if command.road_path_soldier.is_empty():
		return
	var destination_kingdom: KingdomNode = command.road_path_soldier.back().kingdomNode
	var is_missive: bool = command is MissiveCommandResource
	var turns: int
	var quantity: int = ceili(command.road_path_soldier[0].troups_number / 2.0)
	if is_missive:
		turns = (command.road_path_missive.size() - 1) + (command.road_path_soldier.size() - 1)
	else:
		turns = command.road_path_soldier.size() - 1
	var stack_index: int = _icons.filter(func(i): return is_instance_valid(i) and i.get_parent() == destination_kingdom).size()
	var icon: IncomingUnitIcon = _create_icon(destination_kingdom, is_missive, quantity, turns, stack_index)
	icon.modulate.a = 0.7
	_command_preview_icon = icon

func hide_command_preview() -> void:
	_command_preview_play.stop()
	if _command_preview_icon != null and is_instance_valid(_command_preview_icon) and not _command_preview_icon.is_queued_for_deletion():
		_command_preview_icon.queue_free()
	_command_preview_icon = null

func clear_preview() -> void:
	_pinned_icon = null
	icon_click_consumed = false
	_pending_preview.hide()

func turns_to_arrival(handler: Node) -> int:
	if handler is SoldierHandlerNode:
		return max(0, handler.troups.road_path_soldier.size() - 1 - handler.troups.step)
	elif handler is MissiveHandlerNode:
		return max(0, handler.troups.road_path_missive.size() - 1 - handler.troups.step) + (handler.troups.road_path_soldier.size() - 1)
	return 0
	
func clear() -> void:
	_pinned_icon = null
	hide_command_preview()
	_pending_preview.hide()
	for icon in _icons:
		if is_instance_valid(icon) and not icon.is_queued_for_deletion():
			icon.queue_free()
	_icons.clear()
