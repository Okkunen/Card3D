class_name ActionResolver
extends RefCounted


var _battle_manager: Node


func _init(battle_manager: Node) -> void:
	_battle_manager = battle_manager


func resolve_effects(
	source_unit: BattleUnitState,
	card_data: CombatCardData,
	effects: Array[CombatEffectData],
	target_unit: BattleUnitState = null,
	runtime_card: CardRuntimeState = null
	) -> void:
	for effect: CombatEffectData in effects:
		_resolve_effect(source_unit, card_data, effect, target_unit, runtime_card)


func _resolve_effect(
	source_unit: BattleUnitState,
	card_data: CombatCardData,
	effect: CombatEffectData,
	target_unit: BattleUnitState,
	runtime_card: CardRuntimeState
	) -> void:
	var resolved_targets: Array[BattleUnitState] = _battle_manager.get_effect_targets(source_unit, target_unit, effect.target_scope)
	match effect.effect_type:
		&"damage":
			_apply_damage(source_unit, resolved_targets, effect.amount, effect.hits)
		&"block":
			_apply_block(resolved_targets, effect.amount)
		&"apply_status":
			_apply_status(resolved_targets, effect.status_id, effect.status_stacks, effect.duration)
		&"draw":
			_battle_manager.draw_cards_for_owner(source_unit.data.id, effect.amount)
		&"gain_energy":
			_battle_manager.gain_energy(source_unit.data.id, effect.amount)
		&"consume_status_damage":
			_apply_consume_status_damage(source_unit, resolved_targets, effect)
		&"consume_self_status_combo":
			_apply_consume_self_status_combo(source_unit, resolved_targets, effect)
		&"execute":
			_apply_execute(source_unit, resolved_targets, effect)
		&"damage_from_block":
			_apply_damage(source_unit, resolved_targets, effect.amount + int(source_unit.block / maxi(1, effect.secondary_amount)), effect.hits)
		&"reduce_cost_in_hand":
			if runtime_card != null:
				_battle_manager.reduce_random_hand_cost(source_unit.data.id, effect.amount, runtime_card.runtime_id)


func _apply_damage(source_unit: BattleUnitState, targets: Array[BattleUnitState], base_amount: int, hits: int) -> void:
	for target: BattleUnitState in targets:
		for _hit in range(maxi(1, hits)):
			_battle_manager.deal_damage(source_unit, target, base_amount)


func _apply_block(targets: Array[BattleUnitState], amount: int) -> void:
	for target: BattleUnitState in targets:
		_battle_manager.gain_block(target, amount)


func _apply_status(targets: Array[BattleUnitState], status_id: StringName, stacks: int, duration: int) -> void:
	for target: BattleUnitState in targets:
		_battle_manager.apply_status(target, status_id, stacks, duration)


func _apply_consume_status_damage(source_unit: BattleUnitState, targets: Array[BattleUnitState], effect: CombatEffectData) -> void:
	for target: BattleUnitState in targets:
		var consumed: int = _battle_manager.consume_status(target, effect.consume_status_id, maxi(1, effect.consume_amount))
		var total_damage: int = effect.amount
		if consumed > 0:
			total_damage += effect.bonus_amount * consumed
		_battle_manager.deal_damage(source_unit, target, total_damage)
		if consumed > 0 and effect.secondary_amount > 0:
			_battle_manager.apply_status(target, &"slow", effect.secondary_amount, 2)


func _apply_consume_self_status_combo(source_unit: BattleUnitState, targets: Array[BattleUnitState], effect: CombatEffectData) -> void:
	var consumed: int = _battle_manager.consume_status(source_unit, effect.consume_status_id, maxi(1, effect.consume_amount))
	var block_amount: int = effect.amount
	var damage_amount: int = effect.secondary_amount
	if consumed > 0:
		block_amount += effect.bonus_amount
		damage_amount += effect.bonus_amount
	_battle_manager.gain_block(source_unit, block_amount)
	for target: BattleUnitState in targets:
		_battle_manager.deal_damage(source_unit, target, damage_amount)


func _apply_execute(source_unit: BattleUnitState, targets: Array[BattleUnitState], effect: CombatEffectData) -> void:
	for target: BattleUnitState in targets:
		var damage_amount: int = effect.amount
		if target.current_health <= effect.threshold:
			damage_amount += effect.bonus_amount
		_battle_manager.deal_damage(source_unit, target, damage_amount)
