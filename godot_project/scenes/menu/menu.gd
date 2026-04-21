extends Control


@onready var start_button = $CenterContainer/VBoxContainer/StartButton

const LEVEL_SCENE_PATH: String = "scenes/LevelManager.tscn"

func _ready():
	SceneManager.preload_scene(LEVEL_SCENE_PATH)
	start_button.connect("pressed", Callable(self , "_on_start_button_pressed"))

func _on_start_button_pressed() -> void:
	AudioManager.play_music(AudioManager.MUSIC_MENU)
	await SceneManager.change_scene_with_path(LEVEL_SCENE_PATH)
