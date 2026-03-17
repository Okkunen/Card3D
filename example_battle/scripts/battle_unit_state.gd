class_name BattleUnitState
extends RefCounted


var runtime_id: String = ""
var data: CombatUnitData
var current_health: int = 0
var block: int = 0
var statuses: Dictionary = {}
var intent: Dictionary = {}


func setup(unit_data: CombatUnitData, new_runtime_id: String) -> BattleUnitState:
	data = unit_data
	runtime_id = new_runtime_id
	current_health = data.max_health
	block = 0
	statuses = {}
	intent = {}
	return self


func is_alive() -> bool:
	return current_health > 0


func get_status_stacks(status_id: StringName) -> int:
	if not statuses.has(status_id):
		return 0
	return int(statuses[status_id].get("stacks", 0))


func add_status(status_id: StringName, stacks: int, turns: int) -> void:
	if statuses.has(status_id):
		statuses[status_id]["stacks"] = int(statuses[status_id].get("stacks", 0)) + stacks
		if turns > 0:
			statuses[status_id]["turns"] = maxi(int(statuses[status_id].get("turns", 0)), turns)
		return
	statuses[status_id] = {
		"stacks": stacks,
		"turns": turns
	}


func set_status(status_id: StringName, stacks: int, turns: int) -> void:
	statuses[status_id] = {
		"stacks": stacks,
		"turns": turns
	}


func consume_status(status_id: StringName, amount: int) -> int:
	if not statuses.has(status_id):
		return 0
	var current_stacks: int = int(statuses[status_id].get("stacks", 0))
	var consumed: int = mini(current_stacks, amount)
	var remaining: int = current_stacks - consumed
	if remaining <= 0:
		statuses.erase(status_id)
	else:
		statuses[status_id]["stacks"] = remaining
	return consumed


func decrement_status_duration(status_id: StringName) -> bool:
	if not statuses.has(status_id):
		return false
	var turns: int = int(statuses[status_id].get("turns", 0))
	if turns <= 0:
		return false
	turns -= 1
	if turns <= 0:
		statuses.erase(status_id)
		return true
	statuses[status_id]["turns"] = turns
	return false


func get_status_summary(status_registry: Dictionary) -> String:
	if statuses.is_empty():
		return "No status effects"
	var lines: Array[String] = []
	for status_id: StringName in statuses.keys():
		var status_data: StatusEffectData = status_registry.get(status_id)
		var display_name: String = str(status_id).capitalize()
		if status_data != null:
			display_name = status_data.display_name
		var entry: Dictionary = statuses[status_id]
		var turns: int = int(entry.get("turns", 0))
		if turns > 0:
			lines.append("%s %d (%d)" % [display_name, int(entry.get("stacks", 0)), turns])
		else:
			lines.append("%s %d" % [display_name, int(entry.get("stacks", 0))])
	lines.sort()
	return "\n".join(lines)
