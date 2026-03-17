class_name BattleManager
extends Node


signal state_changed()
signal battle_finished(victory: bool)


var content: CombatContent = CombatContent.new()
var state: BattleState = BattleState.new()
var battle_log: Array[String] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _deck_controller: DeckController
var _intent_controller: IntentController = IntentController.new()
var _action_resolver: ActionResolver


func _ready() -> void:
	_rng.randomize()
	_deck_controller = DeckController.new(_rng)
	_action_resolver = ActionResolver.new(self)


func get_encounters() -> Array[EncounterData]:
	return content.encounters


func get_card_data(card_id: StringName) -> CombatCardData:
	return content.get_card(card_id)


func get_status_registry() -> Dictionary:
	return content.statuses


func get_battle_log() -> Array[String]:
	return battle_log.duplicate()


func get_hand(owner_id: StringName) -> Array[CardRuntimeState]:
	var deck_state: DeckState = state.decks.get(owner_id)
	if deck_state == null:
		return []
	return deck_state.hand


func get_deck(owner_id: StringName) -> DeckState:
	return state.decks.get(owner_id)


func get_energy(owner_id: StringName) -> int:
	var deck_state: DeckState = get_deck(owner_id)
	if deck_state == null:
		return 0
	return deck_state.energy


func get_unit_by_runtime_id(runtime_id: String) -> BattleUnitState:
	for unit_state: BattleUnitState in state.heroes:
		if unit_state.runtime_id == runtime_id:
			return unit_state
	for unit_state: BattleUnitState in state.enemies:
		if unit_state.runtime_id == runtime_id:
			return unit_state
	return null


func get_hero_by_id(hero_id: StringName) -> BattleUnitState:
	for hero: BattleUnitState in state.heroes:
		if hero.data.id == hero_id:
			return hero
	return null


func get_living_heroes() -> Array[BattleUnitState]:
	return _get_living_units(state.heroes)


func get_living_enemies() -> Array[BattleUnitState]:
	return _get_living_units(state.enemies)


func start_encounter(encounter_data: EncounterData) -> void:
	state = BattleState.new()
	state.encounter_id = encounter_data.id
	state.encounter_name = encounter_data.display_name
	state.round_number = 1
	state.player_turn = true
	state.battle_over = false
	state.victory = false
	battle_log.clear()

	var warrior_state: BattleUnitState = BattleUnitState.new().setup(content.get_unit(&"warrior"), "warrior")
	var mage_state: BattleUnitState = BattleUnitState.new().setup(content.get_unit(&"mage"), "mage")
	state.heroes = [warrior_state, mage_state]
	state.decks[&"warrior"] = _deck_controller.build_deck(&"warrior", warrior_state.data.starting_deck_ids)
	state.decks[&"mage"] = _deck_controller.build_deck(&"mage", mage_state.data.starting_deck_ids)

	var enemy_ids: Array[StringName] = _spawn_encounter_units(encounter_data)
	state.enemies = []
	for index: int in range(enemy_ids.size()):
		var enemy_data: CombatUnitData = content.get_unit(enemy_ids[index])
		var runtime_id: String = "%s_%d" % [enemy_data.id, index]
		state.enemies.append(BattleUnitState.new().setup(enemy_data, runtime_id))

	_roll_enemy_intents()
	_add_log("Encounter: %s" % encounter_data.display_name)
	_begin_player_turn(true)


func can_select_card(owner_id: StringName, runtime_id: String) -> bool:
	if state.battle_over or not state.player_turn:
		return false
	var hero: BattleUnitState = get_hero_by_id(owner_id)
	if hero == null or not hero.is_alive():
		return false
	var deck_state: DeckState = get_deck(owner_id)
	if deck_state == null:
		return false
	var runtime_card: CardRuntimeState = deck_state.find_in_hand(runtime_id)
	if runtime_card == null:
		return false
	var card_data: CombatCardData = get_card_data(runtime_card.card_id)
	if card_data == null:
		return false
	return runtime_card.get_current_cost(card_data.cost) <= deck_state.energy


func can_play_card(owner_id: StringName, runtime_id: String, target_runtime_id: String, collection_role: StringName) -> bool:
	if not can_select_card(owner_id, runtime_id):
		return false
	var deck_state: DeckState = get_deck(owner_id)
	var runtime_card: CardRuntimeState = deck_state.find_in_hand(runtime_id)
	if runtime_card == null:
		return false
	var card_data: CombatCardData = get_card_data(runtime_card.card_id)
	var target_unit: BattleUnitState = null
	if target_runtime_id != "":
		target_unit = get_unit_by_runtime_id(target_runtime_id)
	if card_data.requires_target():
		if collection_role == &"play_zone":
			return false
		if target_unit == null or not target_unit.is_alive():
			return false
		if card_data.target_mode == &"enemy":
			return target_unit.data.team == &"enemy"
		if card_data.target_mode == &"ally":
			return target_unit.data.team == &"hero"
		return false
	return collection_role == &"play_zone"


func play_card(owner_id: StringName, runtime_id: String, target_runtime_id: String = "") -> bool:
	if not can_select_card(owner_id, runtime_id):
		return false
	var deck_state: DeckState = get_deck(owner_id)
	var runtime_card: CardRuntimeState = deck_state.find_in_hand(runtime_id)
	if runtime_card == null:
		return false
	var card_data: CombatCardData = get_card_data(runtime_card.card_id)
	var target_unit: BattleUnitState = null
	if target_runtime_id != "":
		target_unit = get_unit_by_runtime_id(target_runtime_id)
	if not _is_target_valid(card_data, target_unit):
		return false

	var card_cost: int = runtime_card.get_current_cost(card_data.cost)
	if deck_state.energy < card_cost:
		return false
	deck_state.energy -= card_cost
	_deck_controller.remove_from_hand(deck_state, runtime_id)
	_add_log("%s plays %s" % [content.get_unit(owner_id).display_name, card_data.display_name])
	var source_unit: BattleUnitState = get_hero_by_id(owner_id)
	_action_resolver.resolve_effects(source_unit, card_data, card_data.effects, target_unit, runtime_card)
	if card_data.exhausts:
		_deck_controller.move_to_exhaust(deck_state, runtime_card)
	else:
		_deck_controller.move_to_discard(deck_state, runtime_card)
	_cleanup_after_resolution()
	state_changed.emit()
	return true


func draw_cards_for_owner(owner_id: StringName, count: int) -> void:
	var deck_state: DeckState = get_deck(owner_id)
	if deck_state == null:
		return
	_deck_controller.draw_cards(deck_state, count)


func gain_energy(owner_id: StringName, amount: int) -> void:
	var deck_state: DeckState = get_deck(owner_id)
	if deck_state == null:
		return
	deck_state.energy += amount
	_add_log("%s gains %d energy" % [content.get_unit(owner_id).display_name, amount])


func reduce_random_hand_cost(owner_id: StringName, amount: int, exclude_runtime_id: String = "") -> void:
	var deck_state: DeckState = get_deck(owner_id)
	if deck_state == null:
		return
	if _deck_controller.reduce_random_hand_cost(deck_state, amount, exclude_runtime_id):
		_add_log("%s bends the next play cheaper" % content.get_unit(owner_id).display_name)


func get_effect_targets(source_unit: BattleUnitState, target_unit: BattleUnitState, target_scope: StringName) -> Array[BattleUnitState]:
	match target_scope:
		&"target":
			if target_unit != null and target_unit.is_alive():
				return [target_unit]
			return [_pick_default_target(source_unit)]
		&"self":
			return [source_unit]
		&"all_enemies":
			return _get_living_units(_get_opposing_team(source_unit.data.team))
		&"all_allies":
			return _get_living_units(_get_team_by_name(source_unit.data.team))
		&"random_enemy":
			return [_pick_random_target(_get_living_units(_get_opposing_team(source_unit.data.team)))]
		&"random_hero":
			return [_pick_random_target(get_living_heroes())]
	return []


func deal_damage(source_unit: BattleUnitState, target_unit: BattleUnitState, amount: int) -> int:
	if target_unit == null or not target_unit.is_alive():
		return 0
	var final_amount: int = maxi(0, amount)
	if source_unit != null and source_unit.get_status_stacks(&"strength") > 0:
		final_amount += source_unit.get_status_stacks(&"strength")
	if source_unit != null and source_unit.get_status_stacks(&"weak") > 0:
		final_amount = maxi(0, int(ceil(final_amount * 0.75)))
	if target_unit.get_status_stacks(&"vulnerable") > 0:
		final_amount = int(ceil(final_amount * 1.5))
	var blocked: int = mini(target_unit.block, final_amount)
	target_unit.block -= blocked
	var health_damage: int = final_amount - blocked
	if health_damage > 0:
		target_unit.current_health = maxi(0, target_unit.current_health - health_damage)
	var source_name: String = "Status"
	if source_unit != null:
		source_name = source_unit.data.display_name
	if blocked > 0 and health_damage > 0:
		_add_log("%s hits %s for %d (%d blocked)" % [source_name, target_unit.data.display_name, health_damage, blocked])
	elif blocked > 0:
		_add_log("%s hits %s but block absorbs %d" % [source_name, target_unit.data.display_name, blocked])
	elif health_damage > 0:
		_add_log("%s hits %s for %d" % [source_name, target_unit.data.display_name, health_damage])
	if target_unit.current_health <= 0:
		_add_log("%s is defeated" % target_unit.data.display_name)
	return health_damage


func gain_block(target_unit: BattleUnitState, amount: int) -> void:
	if target_unit == null or not target_unit.is_alive() or amount <= 0:
		return
	target_unit.block += amount
	_add_log("%s gains %d block" % [target_unit.data.display_name, amount])


func apply_status(target_unit: BattleUnitState, status_id: StringName, stacks: int, duration: int = 0) -> void:
	if target_unit == null or not target_unit.is_alive() or status_id == &"" or stacks <= 0:
		return
	var status_data: StatusEffectData = content.get_status(status_id)
	if status_data == null:
		return
	var turns: int = duration
	if turns <= 0:
		turns = status_data.default_duration
	target_unit.add_status(status_id, stacks, turns)
	_add_log("%s gains %s %d" % [target_unit.data.display_name, status_data.display_name, stacks])


func consume_status(target_unit: BattleUnitState, status_id: StringName, amount: int) -> int:
	if target_unit == null:
		return 0
	var consumed: int = target_unit.consume_status(status_id, amount)
	if consumed > 0:
		var status_data: StatusEffectData = content.get_status(status_id)
		var display_name: String = str(status_id).capitalize()
		if status_data != null:
			display_name = status_data.display_name
		_add_log("%s consumes %s %d" % [target_unit.data.display_name, display_name, consumed])
	return consumed


func end_player_turn() -> void:
	if state.battle_over or not state.player_turn:
		return
	for hero: BattleUnitState in state.heroes:
		var deck_state: DeckState = get_deck(hero.data.id)
		if deck_state == null:
			continue
		var retained_runtime_ids: Array[String] = []
		for card_state: CardRuntimeState in deck_state.hand:
			var card_data: CombatCardData = get_card_data(card_state.card_id)
			if card_data != null and card_data.retains:
				retained_runtime_ids.append(card_state.runtime_id)
		_deck_controller.discard_non_retained(deck_state, retained_runtime_ids)

	_process_team_turn_end(&"hero")
	_process_end_player_turn_statuses()
	_begin_enemy_turn()


func _begin_player_turn(initial_turn: bool = false) -> void:
	if state.battle_over:
		return
	state.player_turn = true
	_process_team_turn_start(&"hero")
	if state.battle_over:
		state_changed.emit()
		return
	for owner_id: StringName in [StringName(&"warrior"), StringName(&"mage")]:
		var deck_state: DeckState = get_deck(owner_id)
		if deck_state == null:
			continue
		deck_state.energy = deck_state.energy_per_turn
		draw_cards_for_owner(owner_id, 3)
	if initial_turn:
		_add_log("Player turn begins")
	else:
		_add_log("Round %d" % state.round_number)
	state_changed.emit()


func _begin_enemy_turn() -> void:
	if state.battle_over:
		return
	state.player_turn = false
	_process_team_turn_start(&"enemy")
	if state.battle_over:
		state_changed.emit()
		return
	_add_log("Enemy turn")
	for enemy: BattleUnitState in get_living_enemies():
		if enemy.intent.is_empty():
			continue
		_add_log("%s uses %s" % [enemy.data.display_name, str(enemy.intent.get("label", "Strike"))])
		var raw_effects: Array = enemy.intent.get("effects", [])
		var effects: Array[CombatEffectData] = []
		for effect in raw_effects:
			effects.append(effect)
		_action_resolver.resolve_effects(enemy, null, effects, null, null)
		_cleanup_after_resolution()
		if state.battle_over:
			break
	_process_team_turn_end(&"enemy")
	if state.battle_over:
		state_changed.emit()
		return
	state.round_number += 1
	_roll_enemy_intents()
	_begin_player_turn()


func _roll_enemy_intents() -> void:
	for enemy: BattleUnitState in state.enemies:
		if not enemy.is_alive():
			enemy.intent = {}
			continue
		enemy.intent = _intent_controller.build_intent(enemy, state.round_number)


func _process_team_turn_start(team_name: StringName) -> void:
	var team_units: Array[BattleUnitState] = _get_team_by_name(team_name)
	for unit_state: BattleUnitState in team_units:
		if not unit_state.is_alive():
			continue
		unit_state.block = 0
		var status_ids: Array = unit_state.statuses.keys().duplicate()
		for raw_status_id in status_ids:
			var status_id: StringName = raw_status_id
			var status_data: StatusEffectData = content.get_status(status_id)
			if status_data == null or status_data.tick_timing != &"start_owner_turn":
				continue
			match status_id:
				&"poison":
					deal_damage(null, unit_state, unit_state.get_status_stacks(status_id))
				&"burn":
					deal_damage(null, unit_state, 2)
			unit_state.decrement_status_duration(status_id)
	_check_battle_result()


func _process_team_turn_end(team_name: StringName) -> void:
	var team_units: Array[BattleUnitState] = _get_team_by_name(team_name)
	for unit_state: BattleUnitState in team_units:
		if not unit_state.is_alive():
			continue
		var status_ids: Array = unit_state.statuses.keys().duplicate()
		for raw_status_id in status_ids:
			var status_id: StringName = raw_status_id
			var status_data: StatusEffectData = content.get_status(status_id)
			if status_data == null or status_data.tick_timing != &"end_owner_turn":
				continue
			unit_state.decrement_status_duration(status_id)


func _process_end_player_turn_statuses() -> void:
	for unit_state: BattleUnitState in state.heroes + state.enemies:
		var status_ids: Array = unit_state.statuses.keys().duplicate()
		for raw_status_id in status_ids:
			var status_id: StringName = raw_status_id
			var status_data: StatusEffectData = content.get_status(status_id)
			if status_data == null or status_data.tick_timing != &"end_player_turn":
				continue
			unit_state.decrement_status_duration(status_id)


func _cleanup_after_resolution() -> void:
	_check_battle_result()
	for enemy: BattleUnitState in state.enemies:
		if not enemy.is_alive():
			enemy.intent = {}


func _check_battle_result() -> void:
	if state.battle_over:
		return
	if get_living_enemies().is_empty():
		state.battle_over = true
		state.victory = true
		_add_log("Victory")
		battle_finished.emit(true)
	elif get_living_heroes().is_empty():
		state.battle_over = true
		state.victory = false
		_add_log("Defeat")
		battle_finished.emit(false)


func _spawn_encounter_units(encounter_data: EncounterData) -> Array[StringName]:
	if not encounter_data.fixed_enemy_ids.is_empty():
		return encounter_data.fixed_enemy_ids.duplicate()
	var chosen_enemies: Array[StringName] = []
	var remaining_budget: int = encounter_data.budget
	while chosen_enemies.size() < encounter_data.max_enemies:
		var affordable: Array[StringName] = []
		for enemy_id: StringName in encounter_data.enemy_pool:
			var enemy_data: CombatUnitData = content.get_unit(enemy_id)
			if enemy_data != null and enemy_data.threat_cost <= remaining_budget:
				affordable.append(enemy_id)
		if affordable.is_empty():
			if chosen_enemies.is_empty() and not encounter_data.enemy_pool.is_empty():
				chosen_enemies.append(encounter_data.enemy_pool[0])
			break
		var chosen_id: StringName = affordable[_rng.randi_range(0, affordable.size() - 1)]
		chosen_enemies.append(chosen_id)
		remaining_budget -= maxi(1, content.get_unit(chosen_id).threat_cost)
		if remaining_budget <= 0:
			break
	return chosen_enemies


func _is_target_valid(card_data: CombatCardData, target_unit: BattleUnitState) -> bool:
	if not card_data.requires_target():
		return true
	if target_unit == null or not target_unit.is_alive():
		return false
	if card_data.target_mode == &"enemy":
		return target_unit.data.team == &"enemy"
	if card_data.target_mode == &"ally":
		return target_unit.data.team == &"hero"
	return false


func _pick_default_target(source_unit: BattleUnitState) -> BattleUnitState:
	if source_unit.data.team == &"hero":
		return _pick_random_target(get_living_enemies())
	var guarded_heroes: Array[BattleUnitState] = []
	for hero: BattleUnitState in get_living_heroes():
		if hero.get_status_stacks(&"guard") > 0:
			guarded_heroes.append(hero)
	if not guarded_heroes.is_empty():
		return _pick_random_target(guarded_heroes)
	return _pick_random_target(get_living_heroes())


func _pick_random_target(targets: Array[BattleUnitState]) -> BattleUnitState:
	if targets.is_empty():
		return null
	return targets[_rng.randi_range(0, targets.size() - 1)]


func _get_living_units(units: Array[BattleUnitState]) -> Array[BattleUnitState]:
	var alive_units: Array[BattleUnitState] = []
	for unit_state: BattleUnitState in units:
		if unit_state != null and unit_state.is_alive():
			alive_units.append(unit_state)
	return alive_units


func _get_opposing_team(team_name: StringName) -> Array[BattleUnitState]:
	if team_name == &"hero":
		return state.enemies
	return state.heroes


func _get_team_by_name(team_name: StringName) -> Array[BattleUnitState]:
	if team_name == &"hero":
		return state.heroes
	return state.enemies


func _add_log(message: String) -> void:
	battle_log.append(message)
	if battle_log.size() > 10:
		battle_log = battle_log.slice(battle_log.size() - 10, battle_log.size())
