extends Control


@export var start_button:Button 

const LEVEL_SCENE_PATH: String = "scenes/LevelManager.tscn"

func _ready():
	SceneManager.preload_scene(LEVEL_SCENE_PATH)
	start_button.connect("pressed", Callable(self , "_on_start_button_pressed"))
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("""if (screen.orientation && screen.orientation.lock) {
			screen.orientation.lock('landscape').catch(function(e) { console.warn('orientation lock:', e); });
		}""")

func _on_start_button_pressed() -> void:
	AudioManager.play_music(AudioManager.MUSIC_MENU)
	await SceneManager.change_scene_with_path(LEVEL_SCENE_PATH)
