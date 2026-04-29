class_name PendingMovePreview
extends RefCounted

var _preview_play: PreviewPlay = PreviewPlay.new()

func show_handler(handler: Object) -> void:
	_preview_play.draw_lines = true
	hide()
	var level_node: Node2D = GameManager.level
	if not level_node or not is_instance_valid(handler) or not handler is Node or (handler as Node).is_queued_for_deletion():
		return
	var troups = handler.troups
	var step: int = troups.step

	if handler is MissiveHandlerNode:
		# Missive path: grey for resolved steps, yellow for pending steps
		var pending_missive := _split_and_draw(troups.road_path_missive, step, PreviewPlay.LineType.MISSIVE, level_node)
		# Soldier path has not started yet — draw entirely as pending
		var soldier_path: Array = troups.road_path_soldier
		if soldier_path.size() >= 2:
			_preview_play.draw_line(soldier_path, PreviewPlay.LineType.SOLDIER, level_node)
		_preview_play.play_paths(pending_missive, soldier_path, level_node)
	else:
		# SoldierHandlerNode: draw fully-resolved missive origin in grey if present
		if troups.road_path_missive.size() >= 2:
			_preview_play.draw_line(troups.road_path_missive, PreviewPlay.LineType.PAST, level_node)
		# grey for resolved soldier steps, blue for pending steps
		var pending_soldier := _split_and_draw(troups.road_path_soldier, step, PreviewPlay.LineType.SOLDIER, level_node)
		_preview_play.play_paths([], pending_soldier, level_node)

# Draws the resolved portion in grey and the pending portion in `color`.
# Returns the pending sub-array for animation.
func _split_and_draw(path: Array, step: int, type: PreviewPlay.LineType, level_node: Node2D) -> Array:
	if path.size() < 2:
		return []
	# After play_turn(), step is the departure index — unit is now at step+1.
	var split_idx: int = clampi(step + 1, 0, path.size() - 1)
	if split_idx >= 1:
		_preview_play.draw_line(path.slice(0, split_idx + 1), PreviewPlay.LineType.PAST, level_node)
	var pending: Array = path.slice(split_idx)
	if pending.size() >= 2:
		_preview_play.draw_line(pending, type, level_node)
	return pending

func hide() -> void:
	_preview_play.stop()
