extends Control

const END_SCENE_PATH: String = "res://scenes/end.tscn"
@onready var label:Label = $Label 
@onready var end_menu:Control = $EndMenu
@onready var viewport  :SubViewport = $SubViewportContainer/SubViewport

var eventIndex: int = -1
var eventLastVec: Vector2
var relativeVec : Vector2

func load_level() -> void:
	var level_string = GameManager.get_next_level()
	if level_string:
		var packed_scene: PackedScene = load(level_string)
		viewport.add_child(packed_scene.instantiate())
	else:
		print("No more levels to load.")
		end_menu.visible = true
		var packed_scene: PackedScene = load(END_SCENE_PATH)
		add_child(packed_scene.instantiate())

func _handle_input(event) -> void:
	relativeVec = Vector2(0.0, 0.0)
	relativeVec.x = event.position.x - eventLastVec.x
	relativeVec.y = event.position.y - eventLastVec.y
	eventLastVec.x = event.position.x
	eventLastVec.y = event.position.y
	DragAutoload.drag_vector =relativeVec
	DragAutoload.is_dragging =true
	
func _input(event) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			eventIndex = event.index # use the last finger for moving the camera
			eventLastVec.x = event.position.x
			eventLastVec.y = event.position.y
		elif not event.pressed:
			eventIndex = -1
			relativeVec = Vector2(0,0)
			DragAutoload.drag_vector =relativeVec
			DragAutoload.is_dragging =false
	elif event is InputEventScreenDrag:
		if event.index != eventIndex: return
		_handle_input(event)


func _ready() -> void:
	GameManager.setup()
	load_level()
	GameManager.game_finished.connect(_on_game_finish)
	#SceneManager.preload_scene(END_SCENE_PATH)
	end_menu.visible = false
	pass

func _process(_delta: float) -> void:
	label.text = "Turn : "+str(GameManager.turn)
	
func _on_game_finish() -> void:
	if GameManager.is_last_level():

		return
	end_menu.visible = true
