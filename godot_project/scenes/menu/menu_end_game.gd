extends CenterContainer

@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var next_button: Button = $VBoxContainer/NextButton
@onready var return_button: Button = $VBoxContainer/ReturnButton
@onready var label: Label= $VBoxContainer/Label

const LEVEL_SCENE_PATH: String = "scenes/LevelManager.tscn"
const MENU_SCENE_PATH: String = "scenes/menu/Menu.tscn"

func _ready():
	SceneManager.preload_scene(LEVEL_SCENE_PATH)
	SceneManager.preload_scene(MENU_SCENE_PATH)
	retry_button.pressed.connect(_on_button_retry_pressed)
	next_button.pressed.connect(_on_button_next_level_pressed)
	return_button.pressed.connect(_on_button_menu_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_update_label_winner()

func _on_visibility_changed():
	_update_label_winner()

func _on_button_next_level_pressed() -> void:
	await SceneManager.change_scene_with_path(LEVEL_SCENE_PATH)

func _on_button_menu_pressed() -> void:
	await SceneManager.change_scene_with_path(MENU_SCENE_PATH)

func _on_button_retry_pressed() -> void:
	GameManager.current_level -=1
	await SceneManager.change_scene_with_path(LEVEL_SCENE_PATH)

func _update_label_winner():
	if GameManager.winner_index == 0:
		label.text = "YOU WON !"
	else:
		label.text = "YOU LOST !"
