extends SceneTree


func _initialize() -> void:
	await process_frame

	var battle_manager = load("res://example_battle/scripts/battle_manager.gd").new()
	root.add_child(battle_manager)
	await process_frame

	var encounters = battle_manager.get_encounters()
	if not _assert(not encounters.is_empty(), "Expected encounter data"):
		return
	battle_manager.start_encounter(encounters[0])

	if not _assert(battle_manager.state.heroes.size() == 2, "Expected two heroes"):
		return
	if not _assert(battle_manager.get_living_enemies().size() >= 1, "Expected at least one enemy"):
		return
	if not _assert(battle_manager.get_hand(&"warrior").size() > 0, "Expected warrior draw"):
		return
	if not _assert(battle_manager.get_hand(&"mage").size() > 0, "Expected mage draw"):
		return

	var warrior_play = _find_first_playable_card(battle_manager, &"warrior")
	if not _assert(not warrior_play.is_empty(), "Expected a playable warrior card"):
		return
	if not _assert(
		battle_manager.play_card(&"warrior", warrior_play["runtime_id"], warrior_play["target_id"]),
		"Expected warrior card play to succeed"
	):
		return

	battle_manager.end_player_turn()

	if not _assert(battle_manager.state.player_turn, "Expected enemy turn to resolve back to player turn"):
		return
	if not _assert(battle_manager.state.round_number >= 2, "Expected round to advance"):
		return
	if not _assert(battle_manager.get_energy(&"warrior") == 3, "Expected warrior energy refill"):
		return
	if not _assert(battle_manager.get_energy(&"mage") == 3, "Expected mage energy refill"):
		return

	print("battle smoke test passed")
	quit(0)


func _find_first_playable_card(battle_manager, owner_id: StringName) -> Dictionary:
	for runtime_card in battle_manager.get_hand(owner_id):
		if not battle_manager.can_select_card(owner_id, runtime_card.runtime_id):
			continue
		var card_data = battle_manager.get_card_data(runtime_card.card_id)
		var target_id: String = ""
		match card_data.target_mode:
			&"enemy":
				var enemies = battle_manager.get_living_enemies()
				if enemies.is_empty():
					continue
				target_id = enemies[0].runtime_id
			&"ally":
				var hero = battle_manager.get_hero_by_id(owner_id)
				if hero == null:
					continue
				target_id = hero.runtime_id
		return {
			"runtime_id": runtime_card.runtime_id,
			"target_id": target_id
		}
	return {}


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
