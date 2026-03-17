class_name DeckController
extends RefCounted


var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func build_deck(owner_id: StringName, card_ids: Array[StringName]) -> DeckState:
	var deck_state: DeckState = DeckState.new()
	deck_state.owner_id = owner_id
	var runtime_index: int = 0
	for card_id: StringName in card_ids:
		var card_state: CardRuntimeState = CardRuntimeState.new()
		card_state.card_id = card_id
		card_state.runtime_id = "%s_%02d_%04d" % [owner_id, runtime_index, _rng.randi_range(0, 9999)]
		runtime_index += 1
		deck_state.draw_pile.append(card_state)
	_shuffle(deck_state.draw_pile)
	return deck_state


func draw_cards(deck_state: DeckState, count: int) -> Array[CardRuntimeState]:
	var drawn_cards: Array[CardRuntimeState] = []
	for _i in range(count):
		if deck_state.hand.size() >= deck_state.max_hand_size:
			break
		if deck_state.draw_pile.is_empty():
			reshuffle(deck_state)
		if deck_state.draw_pile.is_empty():
			break
		var card_state: CardRuntimeState = deck_state.draw_pile.pop_back()
		deck_state.hand.append(card_state)
		drawn_cards.append(card_state)
	return drawn_cards


func reshuffle(deck_state: DeckState) -> void:
	if deck_state.discard_pile.is_empty():
		return
	_shuffle(deck_state.discard_pile)
	for card_state: CardRuntimeState in deck_state.discard_pile:
		card_state.cost_modifier = 0
	deck_state.draw_pile.append_array(deck_state.discard_pile)
	deck_state.discard_pile.clear()


func remove_from_hand(deck_state: DeckState, runtime_id: String) -> CardRuntimeState:
	for index: int in range(deck_state.hand.size()):
		if deck_state.hand[index].runtime_id == runtime_id:
			return deck_state.hand.pop_at(index)
	return null


func move_to_discard(deck_state: DeckState, card_state: CardRuntimeState) -> void:
	if card_state == null:
		return
	card_state.cost_modifier = 0
	deck_state.discard_pile.append(card_state)


func move_to_exhaust(deck_state: DeckState, card_state: CardRuntimeState) -> void:
	if card_state == null:
		return
	card_state.cost_modifier = 0
	deck_state.exhaust_pile.append(card_state)


func discard_non_retained(deck_state: DeckState, retained_runtime_ids: Array[String]) -> void:
	var remaining_hand: Array[CardRuntimeState] = []
	for card_state: CardRuntimeState in deck_state.hand:
		if retained_runtime_ids.has(card_state.runtime_id):
			card_state.cost_modifier = 0
			remaining_hand.append(card_state)
		else:
			move_to_discard(deck_state, card_state)
	deck_state.hand = remaining_hand


func reduce_random_hand_cost(deck_state: DeckState, amount: int, exclude_runtime_id: String = "") -> bool:
	var candidates: Array[CardRuntimeState] = []
	for card_state: CardRuntimeState in deck_state.hand:
		if card_state.runtime_id == exclude_runtime_id:
			continue
		candidates.append(card_state)
	if candidates.is_empty():
		return false
	var chosen: CardRuntimeState = candidates[_rng.randi_range(0, candidates.size() - 1)]
	chosen.cost_modifier -= amount
	return true


func _shuffle(cards: Array) -> void:
	for index: int in range(cards.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var value = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = value
