extends Node3D


const BATTLE_CARD_SCENE: PackedScene = preload("res://example_battle/scenes/battle_card_3d.tscn")
const BATTLE_COLLECTION_SCENE: PackedScene = preload("res://example_battle/scenes/battle_collection_3d.tscn")
const HAND_CARD_SCALE: Vector3 = Vector3(1.4, 1.4, 1.0)
const UNIT_CARD_SCALE: Vector3 = Vector3(1.25, 1.25, 1.0)


@onready var battle_manager = $BattleManager
@onready var drag_controller: DragController = $DragController
@onready var warrior_hand = $DragController/WarriorHand
@onready var mage_hand = $DragController/MageHand
@onready var global_play_zone = $DragController/GlobalPlayZone
@onready var unit_targets: Node3D = $DragController/UnitTargets
@onready var unit_views: Node3D = $UnitViews
@onready var encounter_label: Label = $CanvasLayer/EncounterLabel
@onready var turn_label: Label = $CanvasLayer/TurnLabel
@onready var warrior_info: Label = $CanvasLayer/WarriorInfo
@onready var mage_info: Label = $CanvasLayer/MageInfo
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var battle_log: Label = $CanvasLayer/BattleLog
@onready var end_turn_button: Button = $CanvasLayer/EndTurnButton

@onready var hero_anchors: Array[Marker3D] = [
	$HeroAnchors/WarriorAnchor,
	$HeroAnchors/MageAnchor
]
@onready var enemy_anchors: Array[Marker3D] = [
	$EnemyAnchors/EnemyAnchor1,
	$EnemyAnchors/EnemyAnchor2,
	$EnemyAnchors/EnemyAnchor3,
	$EnemyAnchors/EnemyAnchor4,
	$EnemyAnchors/EnemyAnchor5
]

var _encounter_index: int = 0
var _target_collections: Array[Node] = []


func _ready() -> void:
	for collection in [warrior_hand, mage_hand, global_play_zone]:
		collection.battle_root_path = get_path()
	global_play_zone.card_added.connect(_on_target_collection_card_added.bind(global_play_zone))
	battle_manager.state_changed.connect(_refresh_battle_view)
	battle_manager.battle_finished.connect(_on_battle_finished)
	_start_current_encounter()


func can_select_card(card, collection) -> bool:
	return battle_manager.can_select_card(collection.owner_id, card.card_runtime_id)


func can_insert_card(card, collection, from_collection: CardCollection3D) -> bool:
	if from_collection == null:
		return false
	return battle_manager.can_play_card(from_collection.owner_id, card.card_runtime_id, collection.target_owner_id, collection.collection_role)


func _start_current_encounter() -> void:
	var encounters = battle_manager.get_encounters()
	if encounters.is_empty():
		return
	_encounter_index = wrapi(_encounter_index, 0, encounters.size())
	battle_manager.start_encounter(encounters[_encounter_index])


func _refresh_battle_view() -> void:
	_refresh_target_collections()
	_refresh_unit_views()
	_refresh_hands()
	_refresh_hud()


func _refresh_target_collections() -> void:
	for collection in _target_collections:
		drag_controller.remove_card_collection(collection)
		collection.queue_free()
	_target_collections.clear()

	for hero_index: int in range(battle_manager.state.heroes.size()):
		var hero = battle_manager.state.heroes[hero_index]
		if hero_index < hero_anchors.size() and hero.is_alive():
			_spawn_target_collection(hero_anchors[hero_index], &"hero_target", hero.runtime_id)

	var living_enemies = battle_manager.get_living_enemies()
	for enemy_index: int in range(mini(living_enemies.size(), enemy_anchors.size())):
		_spawn_target_collection(enemy_anchors[enemy_index], &"enemy_target", living_enemies[enemy_index].runtime_id)


func _refresh_unit_views() -> void:
	for child: Node in unit_views.get_children():
		child.queue_free()

	for hero_index: int in range(battle_manager.state.heroes.size()):
		if hero_index < hero_anchors.size():
			_spawn_unit_view(battle_manager.state.heroes[hero_index], hero_anchors[hero_index])

	var living_enemies = battle_manager.get_living_enemies()
	for enemy_index: int in range(mini(living_enemies.size(), enemy_anchors.size())):
		_spawn_unit_view(living_enemies[enemy_index], enemy_anchors[enemy_index])


func _refresh_hands() -> void:
	_refresh_hand_collection(warrior_hand, &"warrior")
	_refresh_hand_collection(mage_hand, &"mage")


func _refresh_hand_collection(collection, owner_id: StringName) -> void:
	var existing_cards: Array[Card3D] = collection.remove_all()
	for old_card: Card3D in existing_cards:
		old_card.queue_free()
	var hand_cards = battle_manager.get_hand(owner_id)
	for runtime_card in hand_cards:
		var card_data = battle_manager.get_card_data(runtime_card.card_id)
		if card_data == null:
			continue
		var card_view = BATTLE_CARD_SCENE.instantiate()
		card_view.scale = HAND_CARD_SCALE
		card_view.apply_card_data(card_data, runtime_card)
		collection.append_card(card_view)


func _refresh_hud() -> void:
	encounter_label.text = "Encounter: %s" % battle_manager.state.encounter_name
	var turn_owner: String = "Player"
	if not battle_manager.state.player_turn:
		turn_owner = "Enemy"
	turn_label.text = "Round %d  |  %s turn" % [battle_manager.state.round_number, turn_owner]
	warrior_info.text = _build_hero_info(&"warrior")
	mage_info.text = _build_hero_info(&"mage")
	hint_label.text = "Drag targeted cards onto units. Drop untargeted cards into the center zone. Exposed and Charged expire after the next player turn."
	battle_log.text = "\n".join(battle_manager.get_battle_log())
	end_turn_button.disabled = battle_manager.state.battle_over or not battle_manager.state.player_turn


func _spawn_target_collection(anchor: Marker3D, collection_role: StringName, target_runtime_id: String) -> void:
	var collection = BATTLE_COLLECTION_SCENE.instantiate()
	collection.position = anchor.position
	collection.collection_role = collection_role
	collection.target_owner_id = target_runtime_id
	collection.battle_root_path = get_path()
	unit_targets.add_child(collection)
	drag_controller.add_card_collection(collection)
	collection.card_added.connect(_on_target_collection_card_added.bind(collection))
	_target_collections.append(collection)


func _spawn_unit_view(unit_state, anchor: Marker3D) -> void:
	var card_view = BATTLE_CARD_SCENE.instantiate()
	card_view.position = anchor.position
	card_view.disable_collision()
	card_view.scale = UNIT_CARD_SCALE
	card_view.apply_unit_state(unit_state, battle_manager.get_status_registry())
	unit_views.add_child(card_view)


func _build_hero_info(owner_id: StringName) -> String:
	var hero = battle_manager.get_hero_by_id(owner_id)
	var deck_state = battle_manager.get_deck(owner_id)
	if hero == null or deck_state == null:
		return ""
	var status_text: String = hero.get_status_summary(battle_manager.get_status_registry())
	return "%s  HP %d/%d  Block %d  Energy %d  Draw %d  Discard %d  Exhaust %d\n%s" % [
		hero.data.display_name,
		hero.current_health,
		hero.data.max_health,
		hero.block,
		deck_state.energy,
		deck_state.draw_pile.size(),
		deck_state.discard_pile.size(),
		deck_state.exhaust_pile.size(),
		status_text
	]


func _on_target_collection_card_added(card, collection) -> void:
	if not collection.card_indicies.has(card):
		return
	var owner_id: StringName = &""
	if collection.collection_role == &"play_zone":
		owner_id = card.owner_id
	else:
		owner_id = card.owner_id

	var target_runtime_id: String = collection.target_owner_id
	var index: int = collection.card_indicies[card]
	collection.remove_card(index)
	var played: bool = battle_manager.play_card(owner_id, card.card_runtime_id, target_runtime_id)
	card.queue_free()
	if not played:
		battle_manager.state_changed.emit()


func _on_end_turn_button_pressed() -> void:
	battle_manager.end_player_turn()


func _on_next_encounter_button_pressed() -> void:
	_encounter_index += 1
	_start_current_encounter()


func _on_battle_finished(victory: bool) -> void:
	if victory:
		hint_label.text = "Victory. Try the next encounter to see different enemy counts and synergy windows."
	else:
		hint_label.text = "Defeat. Try the next encounter and protect both heroes."
