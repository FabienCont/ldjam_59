class_name PreviewPlay
extends RefCounted

const SPEED := 130.0

const SOLDIER_SCENE = preload("res://scenes/nodes/soldier_sprite_2d.tscn")
const MISSIVE_SCENE = preload("res://scenes/nodes/missive_sprite_2d.tscn")

enum LineType { MISSIVE, SOLDIER, PAST }

const LINE_COLORS := {
	LineType.MISSIVE: Color(1.0,  0.85, 0.2,  0.55),
	LineType.SOLDIER: Color(0.35, 0.65, 1.0,  0.55),
	LineType.PAST:    Color(0.55, 0.55, 0.55, 0.55),
}
const LINE_OFFSETS := {
	LineType.MISSIVE: -3.0,
	LineType.SOLDIER:  3.0,
	LineType.PAST:     0.0,
}

var draw_lines: bool = true

var _nodes: Array = []
var _tweens: Array = []
var _line_nodes: Array = []

func play(command: BaseCommandResource, parent: Node2D) -> void:
	_stop_markers()
	if command is MissiveCommandResource and command.road_path_missive.size() >= 2:
		_spawn_marker(command.road_path_missive, parent, MISSIVE_SCENE, func():
			if command.road_path_soldier.size() >= 2:
				_spawn_marker(command.road_path_soldier, parent, SOLDIER_SCENE, func(): play(command, parent))
			else:
				play(command, parent)
		)
	elif command.road_path_soldier.size() >= 2:
		_spawn_marker(command.road_path_soldier, parent, SOLDIER_SCENE, func(): play(command, parent))

func _spawn_marker(path: Array, parent: Node2D, scene: PackedScene, on_loop_end: Callable) -> void:
	var marker: Node2D = scene.instantiate()
	marker.top_level = true
	marker.z_index = 10
	marker.modulate.a = 0.7
	marker.global_position = path[0].kingdomNode.global_position
	parent.add_child(marker)
	_nodes.append(marker)
	_loop(marker, path, 0, parent, on_loop_end)

func _loop(marker: Node2D, path: Array, index: int, parent: Node2D, on_loop_end: Callable) -> void:
	if not is_instance_valid(marker) or marker.is_queued_for_deletion():
		return
	var next_index := index + 1
	if next_index >= path.size():
		if is_instance_valid(marker) and not marker.is_queued_for_deletion():
			marker.queue_free()
			_nodes.erase(marker)
		on_loop_end.call()
		return
	var from: Vector2 = path[index].kingdomNode.global_position
	var to: Vector2 = path[next_index].kingdomNode.global_position
	var duration := from.distance_to(to) / SPEED
	var tween := parent.create_tween()
	_tweens.append(tween)
	tween.tween_property(marker, "global_position", to, duration)
	tween.tween_callback(func() -> void:
		_tweens.erase(tween)
		_loop(marker, path, next_index, parent, on_loop_end)
	)
func play_paths(missive_path: Array, soldier_path: Array, parent: Node2D) -> void:
	_stop_markers()
	if missive_path.size() >= 2:
		_spawn_marker(missive_path, parent, MISSIVE_SCENE, func():
			if soldier_path.size() >= 2:
				_spawn_marker(soldier_path, parent, SOLDIER_SCENE, func(): play_paths(missive_path, soldier_path, parent))
			else:
				play_paths(missive_path, soldier_path, parent)
		)
	elif soldier_path.size() >= 2:
		_spawn_marker(soldier_path, parent, SOLDIER_SCENE, func(): play_paths(missive_path, soldier_path, parent))



func draw_line(path: Array, type: LineType, parent: Node2D) -> void:
	if not draw_lines or path.size() < 2:
		return
	var line := Line2D.new()
	line.top_level = true
	line.z_index = 5
	line.default_color = LINE_COLORS[type]
	line.width = 2.0
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for kd in path:
		line.add_point(kd.kingdomNode.global_position + Vector2(0.0, LINE_OFFSETS[type]))
	parent.add_child(line)
	_line_nodes.append(line)

func stop() -> void:
	_stop_markers()
	for line in _line_nodes:
		if is_instance_valid(line) and not line.is_queued_for_deletion():
			line.queue_free()
	_line_nodes.clear()

func _stop_markers() -> void:
	for t in _tweens:
		if t:
			t.kill()
	_tweens.clear()
	for n in _nodes:
		if is_instance_valid(n) and not n.is_queued_for_deletion():
			n.queue_free()
	_nodes.clear()

