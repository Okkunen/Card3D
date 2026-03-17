class_name IntentController
extends RefCounted


func build_intent(enemy: BattleUnitState, round_number: int) -> Dictionary:
	match enemy.data.ai_profile:
		&"bruiser":
			if round_number % 2 == 0:
				return {
					"label": "Heavy Blow",
					"description": "Attack a hero for 10",
					"effects": [_make_effect(&"damage", &"target", 10)]
				}
			return {
				"label": "Crushing Bash",
				"description": "Attack for 7 and apply Vulnerable 1",
				"effects": [
					_make_effect(&"damage", &"target", 7),
					_make_effect(&"apply_status", &"target", 0, &"vulnerable", 1, 2)
				]
			}
		&"skirmisher":
			if round_number % 3 == 0:
				return {
					"label": "Poison Darts",
					"description": "Attack for 4 and apply Poison 2",
					"effects": [
						_make_effect(&"damage", &"target", 4),
						_make_effect(&"apply_status", &"target", 0, &"poison", 2, 3)
					]
				}
			return {
				"label": "Twin Shiv",
				"description": "Attack a random hero twice for 3",
				"effects": [_make_effect(&"damage", &"random_hero", 3, &"", 0, 0, 2)]
			}
		&"defender":
			if round_number % 2 == 0:
				return {
					"label": "Bulwark",
					"description": "Give all enemies 5 block",
					"effects": [_make_effect(&"block", &"all_allies", 5)]
				}
			return {
				"label": "Intercept",
				"description": "Gain 6 block and Guard 1",
				"effects": [
					_make_effect(&"block", &"self", 6),
					_make_effect(&"apply_status", &"self", 0, &"guard", 1, 1)
				]
			}
		&"support":
			if round_number % 2 == 0:
				return {
					"label": "Hex Wave",
					"description": "Apply Weak 1 to all heroes",
					"effects": [_make_effect(&"apply_status", &"all_enemies", 0, &"weak", 1, 2)]
				}
			return {
				"label": "Arc Pulse",
				"description": "Attack a hero for 6 and apply Slow 1",
				"effects": [
					_make_effect(&"damage", &"target", 6),
					_make_effect(&"apply_status", &"target", 0, &"slow", 1, 2)
				]
			}
	return {
		"label": "Strike",
		"description": "Attack for 5",
		"effects": [_make_effect(&"damage", &"target", 5)]
	}


func _make_effect(
	effect_type: StringName,
	target_scope: StringName,
	amount: int,
	status_id: StringName = &"",
	status_stacks: int = 0,
	duration: int = 0,
	hits: int = 1
	) -> CombatEffectData:
	var effect: CombatEffectData = CombatEffectData.new()
	effect.effect_type = effect_type
	effect.target_scope = target_scope
	effect.amount = amount
	effect.status_id = status_id
	effect.status_stacks = status_stacks
	effect.duration = duration
	effect.hits = hits
	return effect
