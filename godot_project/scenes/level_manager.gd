extends Control

const END_SCENE_PATH: String = "menu/EndMenu.tscn"
@onready var label:Label = $Label 
@onready var end_menu:Control = $EndMenu
@onready var camera:Camera2D = $SubViewportContainer/SubViewport/Camera2D

var eventIndex: int = -1
var eventLastVec: Vector2
var relativeVec : Vector2

func _handle_input(event) -> void:
	relativeVec = Vector2(0.0, 0.0)
	relativeVec.x = event.position.x - eventLastVec.x
	relativeVec.y = event.position.y - eventLastVec.y
	eventLastVec.x = event.position.x
	eventLastVec.y = event.position.y
	camera.drag_vector =relativeVec
	camera.is_dragging =true
	
func _input(event) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			eventIndex = event.index # use the last finger for moving the camera
			eventLastVec.x = event.position.x
			eventLastVec.y = event.position.y
		elif not event.pressed:
			eventIndex = -1
			relativeVec = Vector2(0,0)
			camera.drag_vector =relativeVec
			camera.is_dragging =false
	elif event is InputEventScreenDrag:
		if event.index != eventIndex: return
		_handle_input(event)


func _ready() -> void:
	#GameManager.setup(kings);
	GameManager.setup()
	GameManager.game_finished.connect(_on_game_finish)
	SceneManager.preload_scene(END_SCENE_PATH)
	end_menu.visible = false
	pass

func _process(_delta: float) -> void:
	label.text = "Turn:"+str(GameManager.turn)
	
func _on_game_finish() -> void:
	end_menu.visible = true
