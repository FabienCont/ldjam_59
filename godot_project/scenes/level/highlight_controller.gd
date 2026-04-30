class_name HighlightController
extends RefCounted

var kingdom_selected: KingdomNode = null
var kingdomHighlighted: Array[KingdomNode] = []
var highlight_path_missive = []:
	set = set_highlight_path_missive
var highlight_path_soldier = []:
	set = set_highlight_path_soldier
var hovered_command: BaseCommandResource = null:
	set = set_hovered_command

var _incoming_units_controller: IncomingUnitsController
var _level_node: Node2D


func setup(incoming_units_controller: IncomingUnitsController, level_node: Node2D) -> void:
	_incoming_units_controller = incoming_units_controller
	_level_node = level_node


func set_hovered_command(value: BaseCommandResource) -> void:
	hovered_command = value
	highlight_path_soldier = []
	highlight_path_missive = []
	_incoming_units_controller.hide_command_preview()
	if not value:
		return
	if value.road_path_soldier:
		highlight_path_soldier = value.road_path_soldier
	if value is MissiveCommandResource and value.road_path_missive:
		highlight_path_missive = value.road_path_missive
	_incoming_units_controller.show_command_preview(value, _level_node)


func reset_highlight() -> void:
	for kingdom in kingdomHighlighted:
		kingdom.highlight_state = KingdomNode.HighlightState.NONE
	kingdomHighlighted = []
	if kingdom_selected:
		kingdom_selected.highlight_state = KingdomNode.HighlightState.NONE
		kingdom_selected = null
	hovered_command = null


func reset_highlight_except_selected() -> void:
	for kingdom in kingdomHighlighted:
		if kingdom != kingdom_selected:
			kingdom.highlight_state = KingdomNode.HighlightState.NONE
	kingdomHighlighted = []
	hovered_command = null


func set_highlight_path_soldier(value) -> void:
	highlight_path_soldier = value
	for kingdom in highlight_path_soldier:
		if kingdom.kingdomNode == kingdom_selected:
			continue
		if kingdom.kingdomNode not in kingdomHighlighted:
			kingdom.kingdomNode.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
			kingdomHighlighted.append(kingdom.kingdomNode)


func set_highlight_path_missive(value) -> void:
	highlight_path_missive = value
	for kingdom in highlight_path_missive:
		if kingdom.kingdomNode == kingdom_selected:
			continue
		if kingdom.kingdomNode not in kingdomHighlighted:
			kingdom.kingdomNode.highlight_state = KingdomNode.HighlightState.HIGHLIGHT_ARRIVED
			kingdomHighlighted.append(kingdom.kingdomNode)
