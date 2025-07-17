class_name UIManager
extends RefCounted

var main_scene: Control
var player_hp_label: Label
var player_mana_label: Label
var player_shield_label: Label
var ai_hp_label: Label
var ai_mana_label: Label
var ai_shield_label: Label
var turn_label: Label
var game_info_label: Label
var game_over_label: Label
var top_panel_bg: ColorRect
var ui_layer: Control

var card_instances: Array = []
var selected_card_index: int = 0
var original_ui_position: Vector2
var is_screen_shaking: bool = false

var player_turn_color = Color(0.08, 0.13, 0.18, 0.9)
var ai_turn_color = Color(0.15, 0.08, 0.08, 0.9)
var transition_time = 0.8

func setup(main: Control):
	main_scene = main
	_get_ui_references()
	original_ui_position = ui_layer.position

func _get_ui_references():
	player_hp_label = main_scene.player_hp_label
	player_mana_label = main_scene.player_mana_label
	player_shield_label = main_scene.player_shield_label
	ai_hp_label = main_scene.ai_hp_label
	ai_mana_label = main_scene.ai_mana_label
	ai_shield_label = main_scene.ai_shield_label
	turn_label = main_scene.turn_label
	game_info_label = main_scene.game_info_label
	game_over_label = main_scene.game_over_label
	top_panel_bg = main_scene.top_panel_bg
	ui_layer = main_scene.ui_layer

func update_all_labels(player: Player, ai: Player):
	update_player_hp(player.current_hp)
	update_player_mana(player.current_mana)
	update_player_shield(player.current_shield)
	update_ai_hp(ai.current_hp)
	update_ai_mana(ai.current_mana)
	update_ai_shield(ai.current_shield)

func update_player_hp(new_hp: int):
	player_hp_label.text = str(new_hp)

func update_player_mana(new_mana: int):
	player_mana_label.text = str(new_mana)

func update_player_shield(new_shield: int):
	player_shield_label.text = str(new_shield)

func update_ai_hp(new_hp: int):
	ai_hp_label.text = str(new_hp)

func update_ai_mana(new_mana: int):
	ai_mana_label.text = str(new_mana)

func update_ai_shield(new_shield: int):
	ai_shield_label.text = str(new_shield)

func start_player_turn(player: Player, difficulty: String):
	var tween = main_scene.create_tween()
	tween.tween_property(top_panel_bg, "color", player_turn_color, transition_time)
	
	player.start_turn()
	var max_cards = player.get_max_cards_per_turn()
	var cards_played = player.get_cards_played()
	
	turn_label.text = "Tu turno"
	
	var difficulty_name = difficulty.to_upper()
	game_info_label.text = "Cartas: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty_name
	
	var end_turn_button = main_scene.end_turn_button
	if end_turn_button:
		end_turn_button.disabled = false

func start_ai_turn(ai: Player):
	var tween = main_scene.create_tween()
	tween.tween_property(top_panel_bg, "color", ai_turn_color, transition_time)
	
	ai.start_turn()
	turn_label.text = "Turno de la IA"
	game_info_label.text = "La IA está jugando..."
	
	var end_turn_button = main_scene.end_turn_button
	if end_turn_button:
		end_turn_button.disabled = true
		end_turn_button.release_focus()

func update_hand_display(player: Player, card_scene: PackedScene, hand_container: Container):
	for child in hand_container.get_children():
		child.queue_free()
	
	card_instances.clear()
	
	for i in range(player.hand.size()):
		var card_data = player.hand[i]
		var card_instance = card_scene.instantiate()
		card_instance.set_card_data(card_data)
		card_instance.card_clicked.connect(main_scene._on_card_clicked)
		
		if card_instance.has_signal("mouse_entered"):
			card_instance.mouse_entered.connect(_on_card_hover)
		
		hand_container.add_child(card_instance)
		card_instances.append(card_instance)
		
		var can_play = main_scene.is_player_turn and player.can_play_card(card_data)
		card_instance.set_playable(can_play)
	
	selected_card_index = clamp(selected_card_index, 0, max(0, card_instances.size() - 1))
	
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.update_cards_available(card_instances.size() > 0)

func _on_card_hover():
	var input_manager = main_scene.input_manager
	if input_manager and not input_manager.gamepad_mode:
		var audio_helper = main_scene.audio_helper
		if audio_helper:
			audio_helper.play_card_hover_sound()

func update_turn_button_text(player: Player, end_turn_button: Button, gamepad_mode: bool):
	if not end_turn_button or not player:
		return
		
	var cards_played = player.get_cards_played()
	var max_cards = player.get_max_cards_per_turn()
	var playable_cards = DeckManager.get_playable_cards(player.hand, player.current_mana)
	
	if cards_played >= max_cards:
		end_turn_button.text = "Esperando"
	elif playable_cards.size() == 0:
		end_turn_button.text = "Sin cartas jugables"
	elif player.get_hand_size() == 0:
		end_turn_button.text = "Sin cartas en mano"
	else:
		if gamepad_mode:
			end_turn_button.text = "🎮 Terminar Turno"
		else:
			end_turn_button.text = "Terminar Turno"

func update_cards_played_info(cards_played: int, max_cards: int, difficulty: String):
	var difficulty_name = difficulty.to_upper()
	game_info_label.text = "Cartas: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty_name

func update_damage_bonus_indicator(player: Player, damage_bonus_label: Label):
	var damage_bonus = player.get_damage_bonus()
	
	if damage_bonus > 0:
		var bonus_text = ""
		var bonus_color = Color.WHITE
		
		match damage_bonus:
			1:
				bonus_text = "⚔️ +1 DMG"
				bonus_color = Color(1.0, 0.8, 0.2, 1.0)
			2:
				bonus_text = "⚔️ +2 DMG"
				bonus_color = Color(1.0, 0.4, 0.2, 1.0)
			3:
				bonus_text = "💀 +3 DMG"
				bonus_color = Color(1.0, 0.2, 0.2, 1.0)
			4:
				bonus_text = "🔥 +4 DMG"
				bonus_color = Color(0.8, 0.2, 0.8, 1.0)
			_:
				bonus_text = "⚔️ +" + str(damage_bonus) + " DMG"
				bonus_color = Color(0.6, 0.2, 0.6, 1.0)
		
		if damage_bonus_label:
			damage_bonus_label.text = bonus_text
			damage_bonus_label.modulate = bonus_color
			damage_bonus_label.visible = true
	else:
		if damage_bonus_label:
			damage_bonus_label.visible = false

func show_damage_bonus_info(turn_num: int, damage_bonus: int):
	turn_label.text = "Turno " + str(turn_num)
	game_info_label.text = "¡Bonus de daño: +" + str(damage_bonus) + "!"

func show_reshuffle_info(player_name: String):
	turn_label.text = player_name + " remezcló"
	if player_name == "Jugador":
		game_info_label.text = "Cartas devueltas al mazo"
	else:
		game_info_label.text = "Algunas cartas volvieron a su mazo"

func play_damage_effects(damage_amount: int):
	if is_screen_shaking:
		return
   
	var shake_intensity = min(damage_amount * 2.0, 8.0)
	screen_shake(shake_intensity, 0.3)

func screen_shake(intensity: float, duration: float):
	if is_screen_shaking:
		return
   
	is_screen_shaking = true
   
	var shake_count = 8
	var time_per_shake = duration / shake_count
   
	for i in range(shake_count):
		var current_intensity = intensity * (1.0 - float(i) / shake_count)
		var shake_x = randf_range(-current_intensity, current_intensity)
		var shake_y = randf_range(-current_intensity, current_intensity)
		var shake_position = original_ui_position + Vector2(shake_x, shake_y)
   	
		var tween = main_scene.create_tween()
		tween.tween_property(ui_layer, "position", shake_position, time_per_shake)
		await tween.finished
   
	var final_tween = main_scene.create_tween()
	final_tween.tween_property(ui_layer, "position", original_ui_position, 0.1)
	await final_tween.finished
   
	is_screen_shaking = false

func update_card_selection(gamepad_mode: bool, player: Player):
	if not gamepad_mode or not main_scene.is_player_turn:
		return
		
	for i in range(card_instances.size()):
		var card = card_instances[i]
		if i == selected_card_index:
			card.modulate = Color(1.3, 1.3, 1.0, 1.0)
			card.z_index = 15
			card.scale = card.original_scale * 1.1
		else:
			if player.can_play_card(player.hand[i]):
				card.modulate = Color.WHITE
			else:
				card.modulate = Color(0.4, 0.4, 0.4, 0.7)
			card.z_index = 0
			card.scale = card.original_scale

func navigate_cards(direction: int, player: Player):
	"""Navega por las cartas con gamepad. direction: -1 para izquierda, 1 para derecha"""
	if card_instances.size() == 0:
		return false
		
	selected_card_index = (selected_card_index + direction) % card_instances.size()
	if selected_card_index < 0:
		selected_card_index = card_instances.size() - 1
		
	update_card_selection(true, player)
	return true

func get_selected_card():
	if card_instances.size() > 0 and selected_card_index < card_instances.size():
		return card_instances[selected_card_index]
	return null
