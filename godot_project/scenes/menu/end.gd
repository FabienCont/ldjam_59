extends Control

const MENU_SCENE_PATH: String = "scenes/menu/Menu.tscn"
@export var return_menu_button: Button

func _ready() -> void:
	return_menu_button.pressed.connect(_on_pressed)
	
func _on_pressed() -> void:
	await SceneManager.change_scene_with_path(MENU_SCENE_PATH)