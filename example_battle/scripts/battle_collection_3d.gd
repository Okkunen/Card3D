class_name BattleCollection3D
extends CardCollection3D


@export var collection_role: StringName = &"hand"
@export var owner_id: StringName = &""
@export var target_owner_id: String = ""
@export var battle_root_path: NodePath


func can_select_card(card: Card3D) -> bool:
	if collection_role != &"hand":
		return false
	var battle_root = _get_battle_root()
	if battle_root == null:
		return false
	return battle_root.can_select_card(card, self)


func can_remove_card(card: Card3D) -> bool:
	return can_select_card(card)


func can_reorder_card(_card: Card3D) -> bool:
	return collection_role == &"hand"


func can_insert_card(card: Card3D, from_collection: CardCollection3D) -> bool:
	if collection_role == &"hand":
		return false
	var battle_root = _get_battle_root()
	if battle_root == null:
		return false
	return battle_root.can_insert_card(card, self, from_collection)


func _get_battle_root():
	if battle_root_path == NodePath():
		return null
	return get_node_or_null(battle_root_path)
