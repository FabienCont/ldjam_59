extends Control

const END_SCENE_PATH: String = "res://scenes/menu/end.tscn"
const SOLDIER_TEXTURE = preload("res://assets/sprites/icon_soldier_16x16.aseprite")
const MISSIVE_TEXTURE = preload("res://assets/sprites/icon_missive_16x16.aseprite")
const PENDING_SHADER = preload("res://assets/shader/pending_move.gdshader")

@export var end_menu:Control 
@export var pause_menu:Control 
@export var viewport  :SubViewport 

@export var turn_label:Label
@export var button_label  :Label 
@export var button_speed1  :Button 
@export var button_speed2  :Button
@export var button_speed4  :Button
@export var skip_turn_button  :Button
@export var command_selected_container: Control
@export var play_turn_button  :Button
@export var cancel_button  :Button
@export var pending_move_icon  :TextureRect
@export var loader  :TextureRect
@export var option_button  :TextureButton

var speed: float = 1.0:
	set= set_speed

func _ready() -> void:
	button_speed1.pressed.connect( _on_speed1_pressed)
	button_speed2.pressed.connect( _on_speed2_pressed)
	button_speed4.pressed.connect( _on_speed4_pressed)
	skip_turn_button.pressed.connect(skip_turn)
	play_turn_button.pressed.connect(_on_play_turn_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	option_button.pressed.connect(_on_option_button_pressed)
	pause_menu.visibility_changed.connect(_on_pause_menu_visibility_changed)
	GameManager.command_selected.connect(_on_command_selected)
	GameManager.command_cancelled.connect(_on_command_ui_cancelled)
	GameManager.start_new_turn.connect(_on_turn_state_changed)
	GameManager.turn_ended.connect(_on_turn_state_changed)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = PENDING_SHADER
	pending_move_icon.material = shader_material
	GameManager.setup()
	load_level()
	GameManager.level_finished.connect(_on_level_finish)
	SceneManager.preload_scene(END_SCENE_PATH)
	end_menu.visible = false
	pause_menu.visible = false
	_update_action_buttons()
	pass

func _process(_delta: float) -> void:
	turn_label.text = "Turn : "+str(GameManager.turn)

func load_level() -> void:
	var level = GameManager.get_next_level()
	if level:
		viewport.add_child(level)
	else:
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

func _on_command_selected(command: BaseCommandResource) -> void:
	if command is MissiveCommandResource:
		pending_move_icon.texture = MISSIVE_TEXTURE
	else:
		pending_move_icon.texture = SOLDIER_TEXTURE
	_update_action_buttons()

func _on_command_ui_cancelled() -> void:
	_update_action_buttons()

func _on_turn_state_changed() -> void:
	_update_action_buttons()

func _update_action_buttons() -> void:
	var is_playing := GameManager.turn_state == GameManager.TurnState.PLAYING
	var is_command_selected := GameManager.turn_state == GameManager.TurnState.COMMAND_SELECTED
	skip_turn_button.visible = not is_command_selected and not is_playing
	command_selected_container.visible = is_command_selected and not is_playing
	loader.visible = is_playing

func _on_option_button_pressed() -> void:
	pause_menu.visible = true

func _on_pause_menu_visibility_changed() -> void:
	if not pause_menu.visible:
		_enable_process()
	else:
		_disable_process()

func _on_play_turn_pressed() -> void:
	GameManager.confirm_command()

func _on_cancel_pressed() -> void:
	GameManager.cancel_command()

func skip_turn() -> void:
	GameManager.skip_turn()
	pass

func _disable_process() -> void:
	if GameManager.level:
		GameManager.level.process_mode =  Node.PROCESS_MODE_DISABLED
		AudioManager.pause_game_audio()

func _enable_process() -> void:
	if GameManager.level:
		GameManager.level.process_mode =  Node.PROCESS_MODE_INHERIT
		AudioManager.resume_game_audio()
