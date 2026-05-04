extends Control

@export var retry_button: Button
@export var return_button: Button
@export var close_button: TextureButton

const LEVEL_SCENE_PATH: String = "scenes/LevelManager.tscn"
const MENU_SCENE_PATH: String = "scenes/menu/Menu.tscn"

func _ready():
	SceneManager.preload_scene(LEVEL_SCENE_PATH)
	SceneManager.preload_scene(MENU_SCENE_PATH)
	retry_button.pressed.connect(_on_button_retry_pressed)
	return_button.pressed.connect(_on_button_menu_pressed)  
	close_button.pressed.connect(_on_button_close_pressed)  

func _on_button_menu_pressed() -> void:
	await SceneManager.change_scene_with_path(MENU_SCENE_PATH)

func _on_button_retry_pressed() -> void:
	GameManager.current_level -=1
	await SceneManager.change_scene_with_path(LEVEL_SCENE_PATH)

func _on_button_close_pressed() -> void:
	visible = false
