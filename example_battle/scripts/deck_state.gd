class_name DeckState
extends RefCounted


var owner_id: StringName = &""
var draw_pile: Array[CardRuntimeState] = []
var hand: Array[CardRuntimeState] = []
var discard_pile: Array[CardRuntimeState] = []
var exhaust_pile: Array[CardRuntimeState] = []
var max_hand_size: int = 5
var energy: int = 0
var energy_per_turn: int = 3


func find_in_hand(runtime_id: String) -> CardRuntimeState:
	for card_state: CardRuntimeState in hand:
		if card_state.runtime_id == runtime_id:
			return card_state
	return null
