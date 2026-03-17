class_name CombatContent
extends RefCounted


var cards: Dictionary = {}
var units: Dictionary = {}
var statuses: Dictionary = {}
var encounters: Array[EncounterData] = []


func _init() -> void:
	_build_statuses()
	_build_cards()
	_build_units()
	_build_encounters()


func get_card(card_id: StringName) -> CombatCardData:
	return cards.get(card_id)


func get_unit(unit_id: StringName) -> CombatUnitData:
	return units.get(unit_id)


func get_status(status_id: StringName) -> StatusEffectData:
	return statuses.get(status_id)


func _build_statuses() -> void:
	statuses[&"exposed"] = _status(&"exposed", "Exposed", &"debuff", 2, &"end_player_turn", true, "Consumed by mage payoff cards.")
	statuses[&"charged"] = _status(&"charged", "Charged", &"buff", 2, &"end_player_turn", true, "Consumed by warrior payoff cards.")
	statuses[&"weak"] = _status(&"weak", "Weak", &"debuff", 2, &"end_owner_turn", false, "Deal 25% less damage.")
	statuses[&"vulnerable"] = _status(&"vulnerable", "Vulnerable", &"debuff", 2, &"end_owner_turn", false, "Take 50% more damage.")
	statuses[&"poison"] = _status(&"poison", "Poison", &"debuff", 3, &"start_owner_turn", false, "Take damage at turn start.")
	statuses[&"burn"] = _status(&"burn", "Burn", &"debuff", 2, &"start_owner_turn", false, "Take 2 damage at turn start.")
	statuses[&"slow"] = _status(&"slow", "Slow", &"debuff", 2, &"end_owner_turn", false, "Intent loses pace; mainly a combo rider.")
	statuses[&"guard"] = _status(&"guard", "Guard", &"buff", 1, &"start_owner_turn", false, "Enemies favor guarded heroes.")
	statuses[&"strength"] = _status(&"strength", "Strength", &"buff", 0, &"none", false, "Deal more damage.")


func _build_cards() -> void:
	var warrior_bg: Color = Color(0.20, 0.19, 0.17, 1.0)
	var warrior_accent: Color = Color(0.82, 0.44, 0.24, 1.0)
	var mage_bg: Color = Color(0.16, 0.18, 0.24, 1.0)
	var mage_accent: Color = Color(0.28, 0.64, 0.92, 1.0)

	cards[&"iron_slash"] = _card(&"iron_slash", "Iron Slash", &"warrior", 1, &"attack", &"enemy", "Deal 6 damage.", warrior_accent, warrior_bg, [
		_effect(&"damage", &"target", 6)
	])
	cards[&"shield_up"] = _card(&"shield_up", "Shield Up", &"warrior", 1, &"skill", &"none", "Gain 7 block.", warrior_accent, warrior_bg, [
		_effect(&"block", &"self", 7)
	])
	cards[&"expose_weakness"] = _card(&"expose_weakness", "Expose Weakness", &"warrior", 1, &"attack", &"enemy", "Deal 4 damage. Apply Exposed 2.", warrior_accent, warrior_bg, [
		_effect(&"damage", &"target", 4),
		_effect(&"apply_status", &"target", 0, &"exposed", 2, 2)
	])
	cards[&"guard_swap"] = _card(&"guard_swap", "Guard Swap", &"warrior", 1, &"skill", &"ally", "An ally gains 6 block and Guard 1.", warrior_accent, warrior_bg, [
		_effect(&"block", &"target", 6),
		_effect(&"apply_status", &"target", 0, &"guard", 1, 1)
	])
	cards[&"bulwark_charge"] = _card(&"bulwark_charge", "Bulwark Charge", &"warrior", 1, &"skill", &"enemy", "Gain 6 block. If Charged, consume 1 for +4 block and deal 8 damage.", warrior_accent, warrior_bg, [
		_self_combo_effect(&"target", 6, 8, &"charged", 1, 4)
	])
	cards[&"crash_armor"] = _card(&"crash_armor", "Crash Armor", &"warrior", 2, &"attack", &"enemy", "Deal 8 damage plus 1 per 2 block.", warrior_accent, warrior_bg, [
		_damage_from_block_effect(&"target", 8, 2)
	])
	cards[&"relay_strike"] = _card(&"relay_strike", "Relay Strike", &"warrior", 1, &"attack", &"enemy", "Deal 5 damage. If Charged, consume 1 for +4 damage.", warrior_accent, warrior_bg, [
		_effect(&"consume_status_damage", &"target", 5, &"", 0, 0, 1, &"charged", 1, 4)
	])
	cards[&"taunting_blow"] = _card(&"taunting_blow", "Taunting Blow", &"warrior", 1, &"attack", &"enemy", "Deal 5 damage and gain Guard 1.", warrior_accent, warrior_bg, [
		_effect(&"damage", &"target", 5),
		_effect(&"apply_status", &"self", 0, &"guard", 1, 1)
	])
	cards[&"stand_fast"] = _card(&"stand_fast", "Stand Fast", &"warrior", 0, &"skill", &"none", "Gain 4 block. Retain.", warrior_accent, warrior_bg, [
		_effect(&"block", &"self", 4)
	], true)
	cards[&"finishing_cut"] = _card(&"finishing_cut", "Finishing Cut", &"warrior", 1, &"attack", &"enemy", "Deal 5 damage. If target has 10 or less HP, deal 8 more.", warrior_accent, warrior_bg, [
		_execute_effect(&"target", 5, 10, 8)
	])

	cards[&"arc_bolt"] = _card(&"arc_bolt", "Arc Bolt", &"mage", 1, &"attack", &"enemy", "Deal 6 damage.", mage_accent, mage_bg, [
		_effect(&"damage", &"target", 6)
	])
	cards[&"frost_ward"] = _card(&"frost_ward", "Frost Ward", &"mage", 1, &"skill", &"ally", "An ally gains 6 block.", mage_accent, mage_bg, [
		_effect(&"block", &"target", 6)
	])
	cards[&"static_charge"] = _card(&"static_charge", "Static Charge", &"mage", 1, &"skill", &"ally", "Apply Charged 1. Draw 1.", mage_accent, mage_bg, [
		_effect(&"apply_status", &"target", 0, &"charged", 1, 2),
		_effect(&"draw", &"self", 1)
	])
	cards[&"sunder_hex"] = _card(&"sunder_hex", "Sunder Hex", &"mage", 1, &"attack", &"enemy", "Deal 5 damage. If Exposed, consume 1 for +8 damage and Slow 1.", mage_accent, mage_bg, [
		_effect(&"consume_status_damage", &"target", 5, &"", 0, 0, 1, &"exposed", 1, 8, 1)
	])
	cards[&"ember_rain"] = _card(&"ember_rain", "Ember Rain", &"mage", 2, &"attack", &"none", "Deal 5 damage and apply Burn 1 to all enemies.", mage_accent, mage_bg, [
		_effect(&"damage", &"all_enemies", 5),
		_effect(&"apply_status", &"all_enemies", 0, &"burn", 1, 2)
	])
	cards[&"crippling_mist"] = _card(&"crippling_mist", "Crippling Mist", &"mage", 1, &"skill", &"none", "Apply Weak 1 to all enemies.", mage_accent, mage_bg, [
		_effect(&"apply_status", &"all_enemies", 0, &"weak", 1, 2)
	])
	cards[&"insight"] = _card(&"insight", "Insight", &"mage", 0, &"skill", &"none", "Draw 2. Reduce the cost of a random card in your hand by 1.", mage_accent, mage_bg, [
		_effect(&"draw", &"self", 2),
		_effect(&"reduce_cost_in_hand", &"self", 1)
	], false, true)
	cards[&"mana_surge"] = _card(&"mana_surge", "Mana Surge", &"mage", 0, &"skill", &"none", "Gain 1 energy.", mage_accent, mage_bg, [
		_effect(&"gain_energy", &"self", 1)
	])
	cards[&"null_spark"] = _card(&"null_spark", "Null Spark", &"mage", 1, &"attack", &"enemy", "Deal 4 damage. Apply Vulnerable 1.", mage_accent, mage_bg, [
		_effect(&"damage", &"target", 4),
		_effect(&"apply_status", &"target", 0, &"vulnerable", 1, 2)
	])
	cards[&"mirror_barrier"] = _card(&"mirror_barrier", "Mirror Barrier", &"mage", 1, &"skill", &"ally", "An ally gains 8 block. Retain.", mage_accent, mage_bg, [
		_effect(&"block", &"target", 8)
	], true)


func _build_units() -> void:
	units[&"warrior"] = _unit(
		&"warrior",
		"Vanguard",
		&"hero",
		&"warrior",
		42,
		0,
		Color(0.82, 0.44, 0.24, 1.0),
		Color(0.20, 0.19, 0.17, 1.0),
		[
			&"iron_slash", &"iron_slash", &"iron_slash",
			&"shield_up", &"shield_up", &"shield_up",
			&"expose_weakness", &"expose_weakness",
			&"guard_swap", &"bulwark_charge", &"crash_armor", &"relay_strike"
		],
		&"",
		"Frontliner who sets up Exposed and cashes in Charged."
	)
	units[&"mage"] = _unit(
		&"mage",
		"Arcanist",
		&"hero",
		&"mage",
		34,
		0,
		Color(0.28, 0.64, 0.92, 1.0),
		Color(0.16, 0.18, 0.24, 1.0),
		[
			&"arc_bolt", &"arc_bolt", &"arc_bolt",
			&"frost_ward", &"frost_ward",
			&"static_charge", &"static_charge",
			&"sunder_hex", &"ember_rain", &"crippling_mist",
			&"insight", &"mana_surge"
		],
		&"",
		"Support spellcaster who grants Charged and cashes in Exposed."
	)
	units[&"bone_brute"] = _unit(&"bone_brute", "Bone Brute", &"enemy", &"bruiser", 34, 3, Color(0.73, 0.31, 0.28, 1.0), Color(0.24, 0.17, 0.17, 1.0), [], &"bruiser", "High damage bruiser.")
	units[&"knife_imp"] = _unit(&"knife_imp", "Knife Imp", &"enemy", &"skirmisher", 18, 1, Color(0.86, 0.45, 0.30, 1.0), Color(0.22, 0.16, 0.16, 1.0), [], &"skirmisher", "Fast low-HP attacker.")
	units[&"shield_drone"] = _unit(&"shield_drone", "Shield Drone", &"enemy", &"defender", 22, 2, Color(0.76, 0.76, 0.44, 1.0), Color(0.20, 0.19, 0.16, 1.0), [], &"defender", "Protective support defender.")
	units[&"hex_sage"] = _unit(&"hex_sage", "Hex Sage", &"enemy", &"support", 20, 2, Color(0.56, 0.42, 0.84, 1.0), Color(0.18, 0.16, 0.24, 1.0), [], &"support", "Applies debuffs and poke damage.")


func _build_encounters() -> void:
	encounters = [
		_encounter(&"solo_brute", "Solo Brute", 3, 1, [&"bone_brute"]),
		_encounter(&"double_imps", "Double Imps", 2, 2, [&"knife_imp"]),
		_encounter(&"frontline_wall", "Frontline Wall", 4, 2, [&"bone_brute", &"shield_drone"]),
		_encounter(&"sage_and_knives", "Sage and Knives", 4, 3, [&"knife_imp", &"hex_sage"]),
		_encounter(&"mixed_skirmish", "Mixed Skirmish", 5, 3, [&"bone_brute", &"knife_imp", &"shield_drone", &"hex_sage"]),
		_encounter(&"swarm", "Imp Swarm", 5, 5, [&"knife_imp"]),
		_encounter(&"elite_cluster", "Elite Cluster", 6, 4, [&"bone_brute", &"shield_drone", &"hex_sage"]),
		_encounter(&"boss_pack", "Boss Pack", 7, 5, [&"bone_brute", &"knife_imp", &"shield_drone", &"hex_sage"])
	]


func _card(
	card_id: StringName,
	display_name: String,
	owner_id: StringName,
	cost: int,
	card_type: StringName,
	target_mode: StringName,
	description: String,
	accent_color: Color,
	background_color: Color,
	effects: Array[CombatEffectData],
	retains: bool = false,
	exhausts: bool = false
	) -> CombatCardData:
	var card_data: CombatCardData = CombatCardData.new()
	card_data.id = card_id
	card_data.display_name = display_name
	card_data.owner_id = owner_id
	card_data.cost = cost
	card_data.card_type = card_type
	card_data.target_mode = target_mode
	card_data.description = description
	card_data.accent_color = accent_color
	card_data.background_color = background_color
	card_data.effects = effects
	card_data.retains = retains
	card_data.exhausts = exhausts
	return card_data


func _effect(
	effect_type: StringName,
	target_scope: StringName,
	amount: int,
	status_id: StringName = &"",
	status_stacks: int = 0,
	duration: int = 0,
	hits: int = 1,
	consume_status_id: StringName = &"",
	consume_amount: int = 0,
	bonus_amount: int = 0,
	secondary_amount: int = 0
	) -> CombatEffectData:
	var effect: CombatEffectData = CombatEffectData.new()
	effect.effect_type = effect_type
	effect.target_scope = target_scope
	effect.amount = amount
	effect.status_id = status_id
	effect.status_stacks = status_stacks
	effect.duration = duration
	effect.hits = hits
	effect.consume_status_id = consume_status_id
	effect.consume_amount = consume_amount
	effect.bonus_amount = bonus_amount
	effect.secondary_amount = secondary_amount
	return effect


func _damage_from_block_effect(target_scope: StringName, base_damage: int, divisor: int) -> CombatEffectData:
	var effect: CombatEffectData = CombatEffectData.new()
	effect.effect_type = &"damage_from_block"
	effect.target_scope = target_scope
	effect.amount = base_damage
	effect.secondary_amount = divisor
	return effect


func _self_combo_effect(
	target_scope: StringName,
	base_block: int,
	base_damage: int,
	consume_status_id: StringName,
	consume_amount: int,
	bonus_amount: int
	) -> CombatEffectData:
	var effect: CombatEffectData = CombatEffectData.new()
	effect.effect_type = &"consume_self_status_combo"
	effect.target_scope = target_scope
	effect.amount = base_block
	effect.secondary_amount = base_damage
	effect.consume_status_id = consume_status_id
	effect.consume_amount = consume_amount
	effect.bonus_amount = bonus_amount
	return effect


func _execute_effect(target_scope: StringName, base_damage: int, threshold: int, bonus_damage: int) -> CombatEffectData:
	var effect: CombatEffectData = CombatEffectData.new()
	effect.effect_type = &"execute"
	effect.target_scope = target_scope
	effect.amount = base_damage
	effect.threshold = threshold
	effect.bonus_amount = bonus_damage
	return effect


func _unit(
	unit_id: StringName,
	display_name: String,
	team: StringName,
	role: StringName,
	max_health: int,
	threat_cost: int,
	accent_color: Color,
	background_color: Color,
	starting_deck_ids: Array[StringName],
	ai_profile: StringName,
	description: String
	) -> CombatUnitData:
	var unit_data: CombatUnitData = CombatUnitData.new()
	unit_data.id = unit_id
	unit_data.display_name = display_name
	unit_data.team = team
	unit_data.role = role
	unit_data.max_health = max_health
	unit_data.threat_cost = threat_cost
	unit_data.accent_color = accent_color
	unit_data.background_color = background_color
	unit_data.starting_deck_ids = starting_deck_ids
	unit_data.ai_profile = ai_profile
	unit_data.description = description
	return unit_data


func _status(
	status_id: StringName,
	display_name: String,
	category: StringName,
	default_duration: int,
	tick_timing: StringName,
	consumeable: bool,
	description: String
	) -> StatusEffectData:
	var status_data: StatusEffectData = StatusEffectData.new()
	status_data.id = status_id
	status_data.display_name = display_name
	status_data.category = category
	status_data.default_duration = default_duration
	status_data.tick_timing = tick_timing
	status_data.consumeable = consumeable
	status_data.description = description
	return status_data


func _encounter(
	encounter_id: StringName,
	display_name: String,
	budget: int,
	max_enemies: int,
	enemy_pool: Array[StringName]
	) -> EncounterData:
	var encounter_data: EncounterData = EncounterData.new()
	encounter_data.id = encounter_id
	encounter_data.display_name = display_name
	encounter_data.budget = budget
	encounter_data.max_enemies = max_enemies
	encounter_data.enemy_pool = enemy_pool
	return encounter_data
