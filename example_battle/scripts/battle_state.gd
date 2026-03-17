class_name BattleState
extends RefCounted


var heroes: Array[BattleUnitState] = []
var enemies: Array[BattleUnitState] = []
var decks: Dictionary = {}
var round_number: int = 1
var player_turn: bool = true
var encounter_id: StringName = &""
var encounter_name: String = ""
var battle_over: bool = false
var victory: bool = false
