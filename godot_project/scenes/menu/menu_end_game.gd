extends CenterContainer

@onready var button_menu: Button = $VBoxContainer/Button
@onready var label: Label= $VBoxContainer/Label

const LEVEL_SCENE_PATH: String = "scenes/LevelManager.tscn"
const MENU_SCENE_PATH: String = "scenes/menu/Menu.tscn"

func _ready():
	SceneManager.preload_scene(LEVEL_SCENE_PATH)
	button_menu.pressed.connect(_on_button_menu_pressed)
	
	if GameManager.winner_index == 0:
		label.text = "WINNER !"
	else:
		label.text = "YOU LOSE!"


func _on_button_menu_pressed() -> void:
	await SceneManager.change_scene_with_path(MENU_SCENE_PATH)

func _on_button_retry_pressed() -> void:
	await SceneManager.change_scene_with_path(LEVEL_SCENE_PATH)
