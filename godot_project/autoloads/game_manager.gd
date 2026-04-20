extends Node

signal game_finished()
signal start_new_turn()
enum GameState {
	NOT_STARTED,
	STARTED,
	FINISH
}

enum TurnState {
	PLAYING,
	WAITING
}

@onready var kingdomsNodeDico:  Dictionary = {};
@onready var game_state: GameState  = GameState.NOT_STARTED;
@onready var turn_state: TurnState  = TurnState.WAITING;
@onready var player_turn: bool = false;
@onready var turn: int = 0;
@onready var winner_index: int = 0;
@onready var current_level: int = -1;
@onready var levels=['scenes/level_1.tscn']

func restart_level():
	setup()

func reset():
	current_level = -1
	setup()

func is_last_level():
	if current_level == levels.size() -1 :
		return true
	return false

func get_next_level():
	if not is_last_level:
		current_level += 1;
		setup()
	else:
		return null


func setup() -> void:
	kingdomsNodeDico = {};
	game_state  = GameState.NOT_STARTED;
	turn_state  = TurnState.WAITING;
	player_turn = false;
	turn= 0;
	winner_index = 0;
	return;

func start_new_game() -> void:	
	game_state = GameState.STARTED

func play_turn() -> void:
	turn+=1
	start_new_turn.emit()
	turn_state =TurnState.PLAYING

func end_turn() -> void:
	turn_state =TurnState.WAITING

func end_game(winner:int) -> void:
	game_state = GameState.FINISH
	winner_index=winner
	game_finished.emit()
