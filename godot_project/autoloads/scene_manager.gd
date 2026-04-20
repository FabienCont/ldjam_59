extends Control

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var background : ColorRect = $CanvasLayer/ColorRect

func preload_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		printerr("❌ Erreur : La scene ", path, " n'existe pas !")
		return
	ResourceLoader.load_threaded_request(path)

func change_scene_with_path(target: String) -> Node:
	if not ResourceLoader.exists(target):
		printerr("❌ Erreur : La scene ", target, " n'existe pas !")
		return
	
	var status := ResourceLoader.load_threaded_get_status(target)
	var packed_scene: PackedScene
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		packed_scene = ResourceLoader.load_threaded_get(target)
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		while ResourceLoader.load_threaded_get_status(target) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		packed_scene = ResourceLoader.load_threaded_get(target)
	else:
		ResourceLoader.load_threaded_request(target)
		while ResourceLoader.load_threaded_get_status(target) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		packed_scene = ResourceLoader.load_threaded_get(target)
	
	var new_scene: Node = packed_scene.instantiate()
	return await change_scene_with_instantiated_scene(new_scene)
	
func change_scene_with_instantiated_scene(new_scene: Node) -> Node:
	if not new_scene is Node:
		printerr("❌ Erreur : La scene ", new_scene, " n'existe pas !")
		return
		
	var old_scene := get_tree().current_scene
	old_scene.set_process(false) 
	mouse_filter = Control.MOUSE_FILTER_STOP
	await fade_out()
	change_scene(new_scene)
	await fade_in()
	mouse_filter = Control.MOUSE_FILTER_PASS
	return new_scene
	

func fade_out() -> Signal:
	animation_player.play("fade_out")
	return animation_player.animation_finished

func fade_in() -> Signal:
	animation_player.play("fade_in")
	return animation_player.animation_finished

	
func change_scene(new_scene: Node) -> void:
	var tree := get_tree()
	var old_scene := tree.current_scene
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	if old_scene:
		old_scene.queue_free()
