class_name CombatCardData
extends Resource


@export var id: StringName = &""
@export var display_name: String = ""
@export var owner_id: StringName = &""
@export var rarity: StringName = &"common"
@export var card_type: StringName = &"skill"
@export var target_mode: StringName = &"enemy"
@export var cost: int = 1
@export var description: String = ""
@export var retains: bool = false
@export var exhausts: bool = false
@export var tags: Array[StringName] = []
@export var accent_color: Color = Color(0.9, 0.9, 0.9, 1.0)
@export var background_color: Color = Color(0.16, 0.16, 0.18, 1.0)
@export var effects: Array[CombatEffectData] = []


func duplicate_card() -> CombatCardData:
	var copy: CombatCardData = CombatCardData.new()
	copy.id = id
	copy.display_name = display_name
	copy.owner_id = owner_id
	copy.rarity = rarity
	copy.card_type = card_type
	copy.target_mode = target_mode
	copy.cost = cost
	copy.description = description
	copy.retains = retains
	copy.exhausts = exhausts
	copy.tags = tags.duplicate()
	copy.accent_color = accent_color
	copy.background_color = background_color
	copy.effects = []
	for effect: CombatEffectData in effects:
		copy.effects.append(effect.duplicate_effect())
	return copy


func requires_target() -> bool:
	return target_mode == &"enemy" or target_mode == &"ally"
