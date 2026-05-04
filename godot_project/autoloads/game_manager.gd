extends Node

const CURSOR_TEXTURE = preload("res://assets/sprites/pointer.png")

signal level_finished()
signal start_new_turn()
signal turn_ended()
signal command_selected(command: BaseCommandResource)
signal command_cancelled()
enum GameState {
	NOT_STARTED,
	STARTED,
	FINISH
}

enum TurnState {
	PLAYING,
	WAITING,
	COMMAND_SELECTED
}

@onready var kingdoms: Array[KingdomDefinitionResource] = []
@onready var game_state: GameState = GameState.NOT_STARTED;
@onready var turn_state: TurnState = TurnState.WAITING;
@onready var turn: int = 0;
@onready var winner_index: int = 0;
@onready var current_level: int = -1;
@onready var levels=['Level0.tscn','Level2.tscn','Level3.tscn','Level1.tscn']
@onready var turn_controller: TurnController = TurnController.new()
@onready var level: LevelNode = null
@onready var indexPlayer:int = 0
var pending_command: BaseCommandResource = null

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		Input.set_custom_mouse_cursor(CURSOR_TEXTURE, Input.CURSOR_ARROW, Vector2.ZERO)

func restart_level():
	setup()

func reset():
	current_level = -1
	setup()

func has_no_more_levels() -> bool:
	if current_level > levels.size() -1 :
		return true
	return false

func get_next_level() -> Node:
	if not has_no_more_levels():
		current_level += 1;
		setup()
		if(current_level ==1 or current_level ==3):
			AudioManager.play_music(AudioManager.MUSIC_MENU2)
			
		if(current_level ==2):
			AudioManager.play_music(AudioManager.MUSIC_MENU1)
		level = load("res://scenes/level/"+levels[current_level]).instantiate()
		return level
	else:
		return null

func setup() -> void:
	kingdoms = []
	game_state  = GameState.NOT_STARTED;
	turn_state  = TurnState.WAITING;
	turn= 0;
	winner_index = 0;
	pending_command = null;
	return;

func start_new_level() -> void:	
	game_state = GameState.STARTED

func play_command(command: BaseCommandResource) -> void:
	turn_controller.send_command(command)
	var bot_command = BotUtils.get_command_ia(kingdoms,kingdoms[kingdoms.size() - 1], 1)
	turn_controller.send_command(bot_command)
	_play_turn()

func set_pending_command(command: BaseCommandResource) -> void:
	pending_command = command
	turn_state = TurnState.COMMAND_SELECTED
	command_selected.emit(command)

func confirm_command() -> void:
	if turn_state != TurnState.COMMAND_SELECTED or pending_command == null:
		return
	var cmd = pending_command
	pending_command = null
	play_command(cmd)

func cancel_command() -> void:
	if turn_state != TurnState.COMMAND_SELECTED:
		return
	pending_command = null
	turn_state = TurnState.WAITING
	command_cancelled.emit()

func skip_turn() -> void:
	if turn_state == TurnState.WAITING:
		var bot_command = BotUtils.get_command_ia(kingdoms,kingdoms[kingdoms.size() - 1], 1)
		turn_controller.send_command(bot_command)
		_play_turn()

func _play_turn() -> void:
	turn+=1
	turn_state = TurnState.PLAYING
	start_new_turn.emit()

func _end_turn() -> void:
	turn_state =TurnState.WAITING
	turn_ended.emit()
	_check_game_finished()
	
func _check_game_finished() -> bool:
	if kingdoms[0].owner_index == 1:
		_end_level(1)
		return true
	if  kingdoms[kingdoms.size()-1].owner_index == 0 :
		_end_level(0)
		return true
	return false

func _end_level(winner:int) -> void:
	winner_index=winner
	game_state = GameState.FINISH
	level_finished.emit()
