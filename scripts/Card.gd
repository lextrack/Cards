class_name Card
extends Control

@export var card_data: CardData
@onready var name_label = $CardBackground/VBox/HeaderContainer/NameLabel
@onready var cost_label = $CardBackground/VBox/HeaderContainer/CostContainer/CostLabel
@onready var cost_bg = $CardBackground/VBox/HeaderContainer/CostContainer/CostBG
@onready var description_label = $CardBackground/VBox/DescriptionContainer/DescriptionLabel
@onready var card_background = $CardBackground
@onready var card_bg = $CardBackground/CardBG
@onready var card_border = $CardBackground/CardBorder
@onready var card_inner = $CardBackground/CardInner
@onready var card_icon = $CardBackground/VBox/ArtContainer/CardIcon
@onready var stat_value = $CardBackground/VBox/StatsContainer/StatValue
@onready var stat_icon = $CardBackground/VBox/StatsContainer/StatIcon
@onready var rarity_label = $CardBackground/VBox/RarityContainer/RarityLabel
@onready var rarity_bg = $CardBackground/VBox/RarityContainer/RarityBG
@onready var art_bg = $CardBackground/VBox/ArtContainer/ArtBG

signal card_clicked(card: Card)
signal card_played(card: Card)

var original_scale: Vector2
var original_position: Vector2
var is_hovered: bool = false
var is_playable: bool = true
var hover_tween: Tween
var entrance_tween: Tween
var epic_border_tween: Tween
var playable_tween: Tween
var has_played_epic_animation: bool = false
var has_played_entrance: bool = false

func _ready():
	original_scale = scale
	original_position = position
	
	play_entrance_animation()
	
	if card_data:
		update_display()
	
	gui_input.connect(_on_card_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	set_mouse_filter_recursive(self)

func play_entrance_animation():
	if has_played_entrance:
		return
		
	has_played_entrance = true
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	position.y += 15
	
	if entrance_tween:
		entrance_tween.kill()
	
	entrance_tween = create_tween()
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	entrance_tween.tween_property(self, "scale", original_scale, 0.15)
	entrance_tween.tween_property(self, "position:y", original_position.y, 0.15)

func play_selection_animation():
	if not is_playable:
		play_disabled_animation()
		return
		
	if hover_tween:
		hover_tween.kill()
	
	var select_tween = create_tween()
	select_tween.set_parallel(true)
	
	select_tween.tween_property(self, "scale", original_scale * 1.15, 0.06)
	select_tween.tween_property(self, "rotation", 0.04, 0.06)
	
	await select_tween.finished
	
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(self, "scale", original_scale, 0.12)
	return_tween.tween_property(self, "rotation", 0.0, 0.12)

func play_disabled_animation():
	var shake_tween = create_tween()
	shake_tween.set_parallel(true)
	
	shake_tween.tween_property(self, "position:x", original_position.x + 3, 0.05)
	shake_tween.tween_property(self, "position:x", original_position.x - 3, 0.05)
	shake_tween.tween_property(self, "position:x", original_position.x + 2, 0.05)
	shake_tween.tween_property(self, "position:x", original_position.x, 0.05)

func play_card_animation():
	card_played.emit(self)
	
	if hover_tween:
		hover_tween.kill()
	if entrance_tween:
		entrance_tween.kill()
	if epic_border_tween:
		epic_border_tween.kill()
	if playable_tween:
		playable_tween.kill()
	
	var play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -25), 0.2)
	play_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	play_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	
	await play_tween.finished
	queue_free()

func update_display():
	name_label.text = card_data.card_name
	cost_label.text = str(card_data.cost)

	var rarity_text = DeckManager.get_card_rarity_text(card_data)
	rarity_label.text = rarity_text
	
	match card_data.card_type:
		"attack":
			description_label.text = "Deals " + str(card_data.damage) + " damage"
		"heal":
			description_label.text = "Restores " + str(card_data.heal) + " health"
		"shield":
			description_label.text = "Grants " + str(card_data.shield) + " shield"
		_:
			description_label.text = card_data.description
	
	var type_colors = get_card_type_colors(card_data.card_type)
	var rarity_colors = get_rarity_colors()
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	
	card_bg.color = type_colors.background
	card_border.color = type_colors.border
	card_inner.color = type_colors.inner
	cost_bg.color = type_colors.cost_bg
	art_bg.color = type_colors.art_bg

	var rarity_multiplier = rarity_colors[rarity]
	card_border.color = card_border.color * rarity_multiplier
	rarity_bg.color = type_colors.border * 0.8

	apply_rarity_effects(rarity)
	
	match card_data.card_type:
		"attack":
			card_icon.text = "⚔️"
			stat_value.text = str(card_data.damage)
			stat_icon.text = "💥"
			stat_value.modulate = Color.ORANGE_RED
		"heal":
			card_icon.text = "💚"
			stat_value.text = str(card_data.heal)
			stat_icon.text = "❤️"
			stat_value.modulate = Color.LIME_GREEN
		"shield":
			card_icon.text = "🛡️"
			stat_value.text = str(card_data.shield)
			stat_icon.text = "🔰"
			stat_value.modulate = Color.CYAN
		_:
			card_icon.text = "❓"
			stat_value.text = "?"
			stat_icon.text = "❓"
			stat_value.modulate = Color.GRAY

func get_card_type_colors(card_type: String) -> Dictionary:
	match card_type:
		"attack":
			return {
				"background": Color(0.2, 0.1, 0.1, 1),
				"border": Color(0.8, 0.2, 0.2, 1),
				"inner": Color(0.3, 0.15, 0.15, 1),
				"cost_bg": Color(0.6, 0.1, 0.1, 1),
				"art_bg": Color(0.4, 0.2, 0.2, 1)
			}
		"heal":
			return {
				"background": Color(0.1, 0.2, 0.1, 1),
				"border": Color(0.2, 0.8, 0.2, 1),
				"inner": Color(0.15, 0.3, 0.15, 1),
				"cost_bg": Color(0.1, 0.6, 0.1, 1),
				"art_bg": Color(0.2, 0.4, 0.2, 1)
			}
		"shield":
			return {
				"background": Color(0.1, 0.1, 0.2, 1),
				"border": Color(0.2, 0.4, 0.8, 1),
				"inner": Color(0.15, 0.15, 0.3, 1),
				"cost_bg": Color(0.1, 0.2, 0.6, 1),
				"art_bg": Color(0.2, 0.2, 0.4, 1)
			}
		_:
			return {
				"background": Color(0.15, 0.15, 0.15, 1),
				"border": Color(0.5, 0.5, 0.5, 1),
				"inner": Color(0.25, 0.25, 0.25, 1),
				"cost_bg": Color(0.4, 0.4, 0.4, 1),
				"art_bg": Color(0.3, 0.3, 0.3, 1)
			}

func get_rarity_colors() -> Dictionary:
	return {
		"common": 1.0,
		"uncommon": 2.5,
		"rare": 3.2,
		"epic": 4.0
	}

func _on_card_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play_selection_animation()
		if is_playable:
			card_clicked.emit(self)

func _on_mouse_entered():
	if not is_hovered and is_playable:
		is_hovered = true
		
		if hover_tween:
			hover_tween.kill()
		
		hover_tween = create_tween()
		hover_tween.set_parallel(true)
		hover_tween.tween_property(self, "scale", original_scale * 1.08, 0.12)
		hover_tween.tween_property(self, "z_index", 10, 0.06)

func _on_mouse_exited():
	if is_hovered:
		is_hovered = false
		
		if hover_tween:
			hover_tween.kill()
		
		hover_tween = create_tween()
		hover_tween.set_parallel(true)
		hover_tween.tween_property(self, "scale", original_scale, 0.12)
		hover_tween.tween_property(self, "z_index", 0, 0.06)

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		update_display()
		if not has_played_epic_animation:
			call_deferred("play_epic_entrance_animation")

func set_playable(playable: bool):
	is_playable = playable
	
	if playable_tween:
		playable_tween.kill()
	
	playable_tween = create_tween()
	
	if playable:
		playable_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		playable_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.15)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if is_hovered:
			is_hovered = false
			if hover_tween:
				hover_tween.kill()
			hover_tween = create_tween()
			hover_tween.set_parallel(true)
			hover_tween.tween_property(self, "scale", original_scale, 0.12)
			hover_tween.tween_property(self, "z_index", 0, 0.06)

func set_mouse_filter_recursive(node: Node):
	if node is Control:
		var control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	
	for child in node.get_children():
		set_mouse_filter_recursive(child)

func apply_rarity_effects(rarity: String):
	match rarity:
		"uncommon":
			name_label.modulate = Color(0.7, 1.4, 0.9, 1.0)
			cost_label.modulate = Color(0.8, 1.5, 1.0, 1.0)
			card_border.modulate = Color(1.05, 1.2, 1.03, 1.0)
		"rare":
			name_label.modulate = Color(0.8, 1.0, 1.6, 1.0)
			cost_label.modulate = Color(0.9, 1.1, 1.7, 1.0)
			stat_value.modulate = stat_value.modulate * Color(0.7, 1.0, 1.8, 1.0)
			card_icon.modulate = Color(0.9, 1.0, 1.4, 1.0)
			card_border.modulate = Color(1.0, 1.15, 1.5, 1.0)
		"epic":
			name_label.modulate = Color(1.6, 1.1, 1.8, 1.0)
			cost_label.modulate = Color(1.7, 1.2, 1.6, 1.0)
			stat_value.modulate = stat_value.modulate * Color(2.2, 1.3, 2.0, 1.0)
			card_icon.modulate = Color(1.5, 1.2, 1.7, 1.0)
			modulate = Color(1.15, 1.05, 1.2, 1.0)
			card_border.modulate = Color(1.6, 1.2, 1.5, 1.0)

			if epic_border_tween:
				epic_border_tween.kill()
			epic_border_tween = create_tween()
			epic_border_tween.set_loops()
			epic_border_tween.tween_property(card_border, "modulate", Color(1.4, 1.2, 1.5, 1.0), 0.6)
			epic_border_tween.tween_property(card_border, "modulate", Color(1.2, 1.1, 1.3, 1.0), 0.6)
		_:
			pass
			
func play_epic_entrance_animation():
	if not card_data or has_played_epic_animation:
		return
	
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	if rarity == "epic":
		has_played_epic_animation = true
		
		var epic_tween = create_tween()
		epic_tween.set_loops(3)
		epic_tween.set_parallel(true)
		
		epic_tween.tween_property(self, "scale", original_scale * 1.12, 0.18)
		epic_tween.tween_property(self, "scale", original_scale, 0.18)
		
		var original_modulate = modulate
		epic_tween.tween_property(self, "modulate", Color(1.25, 1.08, 1.3, 1.0), 0.18)
		epic_tween.tween_property(self, "modulate", original_modulate, 0.18)
