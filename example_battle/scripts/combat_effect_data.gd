class_name CombatEffectData
extends Resource


@export var effect_type: StringName = &"damage"
@export var target_scope: StringName = &"target"
@export var amount: int = 0
@export var secondary_amount: int = 0
@export var hits: int = 1
@export var status_id: StringName = &""
@export var status_stacks: int = 0
@export var duration: int = 0
@export var consume_status_id: StringName = &""
@export var consume_amount: int = 0
@export var bonus_amount: int = 0
@export var threshold: int = 0


func duplicate_effect() -> CombatEffectData:
	var copy: CombatEffectData = CombatEffectData.new()
	copy.effect_type = effect_type
	copy.target_scope = target_scope
	copy.amount = amount
	copy.secondary_amount = secondary_amount
	copy.hits = hits
	copy.status_id = status_id
	copy.status_stacks = status_stacks
	copy.duration = duration
	copy.consume_status_id = consume_status_id
	copy.consume_amount = consume_amount
	copy.bonus_amount = bonus_amount
	copy.threshold = threshold
	return copy
