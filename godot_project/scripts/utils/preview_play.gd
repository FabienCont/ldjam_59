class_name PreviewPlay
extends RefCounted

const SPEED := 130.0

const SOLDIER_SCENE = preload("res://scenes/nodes/soldier_sprite_2d.tscn")
const MISSIVE_SCENE = preload("res://scenes/nodes/missive_sprite_2d.tscn")

var _nodes: Array = []
var _tweens: Array = []

func play(command: BaseCommandResource, parent: Node2D) -> void:
	stop()
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
func stop() -> void:
	for t in _tweens:
		if t:
			t.kill()
	_tweens.clear()
	for n in _nodes:
		if is_instance_valid(n) and not n.is_queued_for_deletion():
			n.queue_free()
	_nodes.clear()

