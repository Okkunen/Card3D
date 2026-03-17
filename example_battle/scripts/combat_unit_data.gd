class_name CombatUnitData
extends Resource


@export var id: StringName = &""
@export var display_name: String = ""
@export var team: StringName = &"enemy"
@export var role: StringName = &"skirmisher"
@export var max_health: int = 30
@export var threat_cost: int = 1
@export var accent_color: Color = Color(0.85, 0.3, 0.3, 1.0)
@export var background_color: Color = Color(0.16, 0.16, 0.18, 1.0)
@export var starting_deck_ids: Array[StringName] = []
@export var ai_profile: StringName = &""
@export var description: String = ""
