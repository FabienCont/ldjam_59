extends Control

const END_SCENE_PATH: String = "res://scenes/end.tscn"
@onready var end_menu:Control = $EndMenu
@onready var viewport  :SubViewport = $SubViewportContainer/SubViewport

@export var turn_label:Label
@export var button_label  :Label 
@export var button_speed1  :Button 
@export var button_speed2  :Button
@export var button_speed4  :Button
@export var skip_turn_button  :Button

var speed: float = 1.0:
	set= set_speed

func _ready() -> void:
	button_speed1.pressed.connect( _on_speed1_pressed)
	button_speed2.pressed.connect( _on_speed2_pressed)
	button_speed4.pressed.connect( _on_speed4_pressed)
	skip_turn_button.pressed.connect(skip_turn)
	GameManager.setup()
	load_level()
	GameManager.level_finished.connect(_on_level_finish)
	SceneManager.preload_scene(END_SCENE_PATH)
	end_menu.visible = false
	pass

func _process(_delta: float) -> void:
	turn_label.text = "Turn : "+str(GameManager.turn)

func load_level() -> void:
	var level = GameManager.get_next_level()
	if level:
		viewport.add_child(level)
	else:
		print("No more levels to load.")
		end_menu.visible = true
		var packed_scene: PackedScene = load(END_SCENE_PATH)
		add_child(packed_scene.instantiate())

func _on_level_finish() -> void:
	if GameManager.has_no_more_levels():
		return
	end_menu.visible = true

func _on_speed1_pressed() -> void:
	speed = 1.0
	button_label.text = "Speed: x1"
	button_speed1.visible = false
	button_speed2.visible = true
	button_speed4.visible = true

func _on_speed2_pressed() -> void:
	speed = 2.0
	button_label.text = "Speed: x2"
	button_speed1.visible = true
	button_speed2.visible = false
	button_speed4.visible = true

func _on_speed4_pressed() -> void:
	speed = 4.0
	button_label.text = "Speed: x4"
	button_speed1.visible = true
	button_speed2.visible = true
	button_speed4.visible = false

func set_speed(value: float) -> void:
	Engine.time_scale = value

func skip_turn() -> void:
	pass
