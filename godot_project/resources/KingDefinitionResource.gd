class_name KingDefinitionResource
extends Resource


enum KingState {
    WAITING,
    PLAYING,
    END_TURN
}

var king_state: KingState = KingState.WAITING; 
var player_slot: int = -1