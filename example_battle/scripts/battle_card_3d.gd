class_name BattleCard3D
extends Card3D

@export var id: String = ""
@export var display_name: String = ""
@export var owner_id: StringName = &""
@export var owner_label_text: String = ""
@export var card_type_label: String = ""
@export var body_text: String = ""
@export var footer_text: String = ""
@export var energy_cost: int = -1
@export var accent_color: Color = Color(0.9, 0.6, 0.2, 1.0)
@export var background_color: Color = Color(0.16, 0.16, 0.18, 1.0)
@export var card_runtime_id: String = ""

@export var front_material_path: String = "":
	set(value):
		front_material_path = value
		if is_inside_tree():
			_apply_front()

@export var damage: int = 0:
	set(value):
		damage = value
		if is_inside_tree():
			_apply_overlay()

@export var health: int = 0:
	set(value):
		health = value
		if is_inside_tree():
			_apply_overlay()

var _front_material_override := StandardMaterial3D.new()
@onready var front_viewport: SubViewport = $FrontTextureViewport
@onready var front_root: Control = $FrontTextureViewport/FrontTextureRoot
@onready var front_color_fill: ColorRect = $FrontTextureViewport/FrontTextureRoot/FrontColorFill
@onready var front_background: TextureRect = $FrontTextureViewport/FrontTextureRoot/FrontTextureBackground
@onready var accent_band: ColorRect = $FrontTextureViewport/FrontTextureRoot/AccentBand
@onready var cost_label: Label = $FrontTextureViewport/FrontTextureRoot/CostLabel
@onready var owner_label: Label = $FrontTextureViewport/FrontTextureRoot/OwnerLabel
@onready var title_label: Label = $FrontTextureViewport/FrontTextureRoot/TitleLabel
@onready var type_label: Label = $FrontTextureViewport/FrontTextureRoot/TypeLabel
@onready var body_label: Label = $FrontTextureViewport/FrontTextureRoot/BodyLabel
@onready var footer_label: Label = $FrontTextureViewport/FrontTextureRoot/FooterLabel
@onready var front_label: Label = $FrontTextureViewport/FrontTextureRoot/FrontTextureLabel


func _ready() -> void:
	front_viewport.disable_3d = true
	front_viewport.transparent_bg = true
	front_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	front_background.stretch_mode = TextureRect.STRETCH_SCALE
	_front_material_override.albedo_texture = front_viewport.get_texture()
	$CardMesh/CardFrontMesh.set_surface_override_material(0, _front_material_override)
	_apply_front()
	_apply_overlay()


func apply_card_data(card_data: CombatCardData, runtime_card: CardRuntimeState = null) -> void:
	id = str(card_data.id)
	owner_id = card_data.owner_id
	display_name = card_data.display_name
	owner_label_text = str(card_data.owner_id).capitalize()
	card_type_label = "%s  %s" % [str(card_data.card_type).capitalize(), str(card_data.rarity).capitalize()]
	body_text = card_data.description
	footer_text = _build_footer(card_data)
	accent_color = card_data.accent_color
	background_color = card_data.background_color
	energy_cost = card_data.cost
	card_runtime_id = ""
	if runtime_card != null:
		energy_cost = runtime_card.get_current_cost(card_data.cost)
		card_runtime_id = runtime_card.runtime_id
	if is_node_ready():
		_apply_overlay()


func apply_unit_state(unit_state: BattleUnitState, status_registry: Dictionary) -> void:
	id = unit_state.runtime_id
	owner_id = unit_state.data.id
	display_name = unit_state.data.display_name
	owner_label_text = str(unit_state.data.role).capitalize()
	card_type_label = str(unit_state.data.team).capitalize()
	body_text = unit_state.get_status_summary(status_registry)
	footer_text = "HP %d / %d    Block %d" % [unit_state.current_health, unit_state.data.max_health, unit_state.block]
	if unit_state.data.team == &"enemy" and not unit_state.intent.is_empty():
		owner_label_text = unit_state.intent.get("label", "")
		card_type_label = unit_state.intent.get("description", "")
	accent_color = unit_state.data.accent_color
	background_color = unit_state.data.background_color
	energy_cost = -1
	card_runtime_id = ""
	health = unit_state.current_health
	damage = 0
	if is_node_ready():
		_apply_overlay()


func _apply_front() -> void:
	if front_material_path == "":
		front_background.texture = null
		return
	var material = load(front_material_path)
	if material == null:
		return
	if material is StandardMaterial3D and material.albedo_texture != null:
		var texture = material.albedo_texture
		var size: Vector2i = texture.get_size()
		front_background.texture = texture
		front_viewport.size = Vector2i(int(size.x), int(size.y))
		front_root.size = size
		front_root.custom_minimum_size = size
		front_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	$CardMesh/CardFrontMesh.set_surface_override_material(0, material)


func _apply_overlay() -> void:
	if not is_node_ready():
		return
	front_color_fill.color = background_color
	accent_band.color = accent_color
	title_label.text = display_name
	owner_label.text = owner_label_text
	type_label.text = card_type_label
	body_label.text = body_text
	footer_label.text = footer_text
	cost_label.visible = energy_cost >= 0
	if energy_cost >= 0:
		cost_label.text = str(energy_cost)
	front_label.text = ""

	if display_name == "":
		if health > 0:
			front_label.visible = true
			front_label.text = str(health)
			front_label.modulate = Color(1, 0, 0)
			front_label.add_theme_font_size_override("font_size", 100)
		elif damage > 0:
			front_label.visible = true
			front_label.text = "Deal %d\ndamage" % damage
			front_label.modulate = Color(0, 0, 0)
			front_label.add_theme_font_size_override("font_size", 60)
	else:
		front_label.visible = false
	front_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _to_string():
	return id


func _build_footer(card_data: CombatCardData) -> String:
	var traits: Array[String] = []
	traits.append(str(card_data.target_mode).replace("_", " ").capitalize())
	if card_data.retains:
		traits.append("Retain")
	if card_data.exhausts:
		traits.append("Exhaust")
	return " | ".join(traits)
