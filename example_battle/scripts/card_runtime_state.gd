class_name CardRuntimeState
extends RefCounted


var runtime_id: String = ""
var card_id: StringName = &""
var cost_modifier: int = 0


func get_current_cost(base_cost: int) -> int:
	return maxi(0, base_cost + cost_modifier)
