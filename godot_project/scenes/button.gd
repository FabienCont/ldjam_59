extends Button

const MENU_SCENE_PATH: String = "scenes/menu/Menu.tscn"

func _on_pressed() -> void:
	await SceneManager.change_scene_with_path(MENU_SCENE_PATH)
