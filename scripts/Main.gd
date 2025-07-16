extends Control

@onready var player_hp_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/HPStat/HPLabel
@onready var player_mana_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/ManaStat/ManaLabel
@onready var player_shield_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/ShieldStat/ShieldLabel

@onready var ai_hp_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/HPStat/HPLabel
@onready var ai_mana_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/ManaStat/ManaLabel
@onready var ai_shield_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/ShieldStat/ShieldLabel

@onready var hand_container = $UILayer/CenterArea/HandContainer
@onready var turn_label = $UILayer/TopPanel/StatsContainer/CenterInfo/TurnLabel
@onready var game_info_label = $UILayer/TopPanel/StatsContainer/CenterInfo/GameInfoLabel
@onready var end_turn_button = $UILayer/BottomPanel/TurnButtonsContainer/EndTurnButton
@onready var game_over_label = $UILayer/GameOverLabel
@onready var ui_layer = $UILayer
@onready var top_panel_bg = $UILayer/TopPanel/TopPanelBG
@onready var damage_bonus_label = $UILayer/TopPanel/StatsContainer/CenterInfo/DamageBonusLabel
@onready var audio_manager = $AudioManager

var player: Player
var ai: Player
var card_scene = preload("res://scenes/Card.tscn")
var ai_notification_scene = preload("res://scenes/AICardNotification.tscn")
var game_notification_scene = preload("res://scenes/GameNotification.tscn")
var ai_notification: AICardNotification
var game_notification: GameNotification
var is_player_turn: bool = true
var difficulty: String = "normal"
var game_count: int = 1
var original_ui_position: Vector2
var is_screen_shaking: bool = false
var player_turn_color = Color(0.08, 0.13, 0.18, 0.9)
var ai_turn_color = Color(0.15, 0.08, 0.08, 0.9)
var transition_time = 0.8

var selected_card_index: int = 0
var card_instances: Array = []
var gamepad_mode: bool = false
var last_input_was_gamepad: bool = false

var confirmation_overlay: Control
var confirmation_background: ColorRect
var confirmation_panel: Panel
var confirmation_label: Label
var confirm_button: Button
var cancel_button: Button
var is_showing_confirmation: bool = false

@export var controls_panel_scene: PackedScene = preload("res://scenes/ControlsPanel.tscn")
var controls_panel: ControlsPanel

func _ready():
	gamepad_mode = false
	last_input_was_gamepad = false
	
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
		setup_button_navigation()
	else:
		push_error("EndTurnButton no encontrado en la escena")
	
	original_ui_position = ui_layer.position
	
	ai_notification = ai_notification_scene.instantiate()
	add_child(ai_notification)
	
	game_notification = game_notification_scene.instantiate()
	add_child(game_notification)
	
	create_confirmation_dialog()

	controls_panel = controls_panel_scene.instantiate()
	ui_layer.add_child(controls_panel)
	
	difficulty = GameState.get_selected_difficulty()
	print("Iniciando juego con dificultad: ", difficulty)
	
	await handle_scene_entrance()
	
	setup_game()

func create_confirmation_dialog():
	confirmation_overlay = Control.new()
	confirmation_overlay.name = "ConfirmationOverlay"
	confirmation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation_overlay.visible = false
	confirmation_overlay.z_index = 100
	add_child(confirmation_overlay)
	
	confirmation_background = ColorRect.new()
	confirmation_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation_background.color = Color(0, 0, 0, 0.7)
	confirmation_overlay.add_child(confirmation_background)
	
	confirmation_panel = Panel.new()
	confirmation_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	confirmation_panel.custom_minimum_size = Vector2(400, 200)
	confirmation_panel.size = Vector2(400, 200)
	confirmation_panel.position = Vector2(-200, -100)
	confirmation_overlay.add_child(confirmation_panel)
	
	var panel_bg = ColorRect.new()
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.color = Color(0.15, 0.15, 0.25, 0.95)
	confirmation_panel.add_child(panel_bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	confirmation_panel.add_child(vbox)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	confirmation_label = Label.new()
	confirmation_label.text = "¿Volver al menú principal?\nSe perderá el progreso actual"
	confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirmation_label.add_theme_font_size_override("font_size", 16)
	confirmation_label.add_theme_color_override("font_color", Color.WHITE)
	confirmation_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(confirmation_label)
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 30)
	vbox.add_child(button_container)
	
	confirm_button = Button.new()
	confirm_button.text = "✓ SÍ, VOLVER"
	confirm_button.custom_minimum_size = Vector2(140, 45)
	confirm_button.add_theme_font_size_override("font_size", 14)
	confirm_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(confirm_button)
	
	cancel_button = Button.new()
	cancel_button.text = "✗ CANCELAR"
	cancel_button.custom_minimum_size = Vector2(140, 45)
	cancel_button.add_theme_font_size_override("font_size", 14)
	cancel_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(cancel_button)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	confirm_button.focus_neighbor_right = cancel_button.get_path()
	cancel_button.focus_neighbor_left = confirm_button.get_path()
	
	confirm_button.pressed.connect(_on_confirm_exit)
	cancel_button.pressed.connect(_on_cancel_exit)
	
	confirm_button.mouse_entered.connect(_on_confirmation_button_hover.bind(confirm_button))
	cancel_button.mouse_entered.connect(_on_confirmation_button_hover.bind(cancel_button))
	confirm_button.focus_entered.connect(_on_confirmation_button_focus.bind(confirm_button))
	cancel_button.focus_entered.connect(_on_confirmation_button_focus.bind(cancel_button))

func _on_confirmation_button_hover(button: Button):
	play_safe_audio("play_card_hover_sound")
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	
	if not button.mouse_exited.is_connected(_on_confirmation_button_unhover):
		button.mouse_exited.connect(_on_confirmation_button_unhover.bind(button))

func _on_confirmation_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_confirmation_button_focus(button: Button):
	play_safe_audio("play_card_hover_sound")
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	
	if not button.focus_exited.is_connected(_on_confirmation_button_unfocus):
		button.focus_exited.connect(_on_confirmation_button_unfocus.bind(button))

func _on_confirmation_button_unfocus(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func show_exit_confirmation():
	if is_showing_confirmation:
		return
	
	is_showing_confirmation = true
	confirmation_overlay.visible = true
	confirmation_overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(confirmation_overlay, "modulate:a", 1.0, 0.3)
	
	await tween.finished
	
	if gamepad_mode or last_input_was_gamepad:
		cancel_button.grab_focus()
	else:
		cancel_button.grab_focus()

func hide_exit_confirmation():
	if not is_showing_confirmation:
		return
	
	var tween = create_tween()
	tween.tween_property(confirmation_overlay, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	
	confirmation_overlay.visible = false
	is_showing_confirmation = false

func _on_confirm_exit():
	play_safe_audio("play_notification_sound")
	is_showing_confirmation = false
	return_to_menu()

func _on_cancel_exit():
	play_safe_audio("play_card_hover_sound")
	hide_exit_confirmation()

func setup_button_navigation():
	end_turn_button.focus_mode = Control.FOCUS_ALL
	
	end_turn_button.mouse_entered.connect(_on_button_hover.bind(end_turn_button))
	end_turn_button.focus_entered.connect(_on_button_focus.bind(end_turn_button))
	end_turn_button.mouse_exited.connect(_on_button_unhover.bind(end_turn_button))
	end_turn_button.focus_exited.connect(_on_button_unfocus.bind(end_turn_button))

func _on_button_hover(button: Button):
	if not gamepad_mode:
		play_safe_audio("play_card_hover_sound")

func _on_button_focus(button: Button):
	play_safe_audio("play_card_hover_sound")
	
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unhover(button: Button):
	if not gamepad_mode:
		var tween = create_tween()
		tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _on_button_unfocus(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func handle_scene_entrance():
	await get_tree().process_frame
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		print("Main: TransitionManager y overlay disponibles")
		
		if TransitionManager.current_overlay.has_method("is_ready") and TransitionManager.current_overlay.is_ready():
			await TransitionManager.current_overlay.fade_out(0.8)
		else:
			play_direct_entrance()
	else:
		play_direct_entrance()
		
func play_direct_entrance():
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished

func play_safe_audio(method_name: String, params: Array = []):
	if audio_manager and audio_manager.has_method(method_name):
		match params.size():
			0:
				audio_manager.call(method_name)
			1:
				audio_manager.call(method_name, params[0])
			2:
				audio_manager.call(method_name, params[0], params[1])
			_:
				print("Demasiados parámetros para: ", method_name)

func setup_game():
	if player:
		player.queue_free()
	if ai:
		ai.queue_free()
	
	player = Player.new()
	ai = Player.new()
	ai.is_ai = true
	
	player.difficulty = difficulty
	ai.difficulty = difficulty
	
	add_child(player)
	add_child(ai)

	player.hp_changed.connect(_on_player_hp_changed)
	player.mana_changed.connect(_on_player_mana_changed)
	player.shield_changed.connect(_on_player_shield_changed)
	player.player_died.connect(_on_player_died)
	player.hand_changed.connect(_on_player_hand_changed)
	player.deck_empty.connect(_on_player_deck_empty)
	player.deck_reshuffled.connect(_on_player_deck_reshuffled)
	player.cards_played_changed.connect(_on_player_cards_played_changed)
	player.turn_changed.connect(_on_player_turn_changed)
	player.card_drawn.connect(_on_player_card_drawn)
	player.auto_turn_ended.connect(_on_player_auto_turn_ended)
	player.damage_taken.connect(_on_player_damage_taken)
	
	ai.hp_changed.connect(_on_ai_hp_changed)
	ai.mana_changed.connect(_on_ai_mana_changed)
	ai.shield_changed.connect(_on_ai_shield_changed)
	ai.player_died.connect(_on_ai_died)
	ai.hand_changed.connect(_on_ai_hand_changed)
	ai.deck_empty.connect(_on_ai_deck_empty)
	ai.deck_reshuffled.connect(_on_ai_deck_reshuffled)
	ai.cards_played_changed.connect(_on_ai_cards_played_changed)
	ai.turn_changed.connect(_on_ai_turn_changed)
	ai.ai_card_played.connect(_on_ai_card_played)
	
	game_over_label.visible = false
	
	update_all_labels()
	update_hand_display()
	start_player_turn()

func restart_game():
	game_count += 1
	turn_label.text = "¡Nueva partida!"
	selected_card_index = 0
	
	var difficulty_desc = GameBalance.get_difficulty_description(difficulty)
	game_info_label.text = "Partida #" + str(game_count) + " | " + difficulty.to_upper()
	
	play_safe_audio("play_background_music")
	
	await get_tree().create_timer(GameBalance.get_timer_delay("new_game")).timeout
	setup_game()

func update_all_labels():
	var damage_bonus = player.get_damage_bonus()
	
	player_hp_label.text = str(player.current_hp)
	player_mana_label.text = str(player.current_mana)
	player_shield_label.text = str(player.current_shield)
	
	ai_hp_label.text = str(ai.current_hp)
	ai_mana_label.text = str(ai.current_mana)
	ai_shield_label.text = str(ai.current_shield)
	
func update_damage_bonus_indicator():
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

func update_hand_display():
	for child in hand_container.get_children():
		child.queue_free()
	
	card_instances.clear()
	
	for i in range(player.hand.size()):
		var card_data = player.hand[i]
		var card_instance = card_scene.instantiate()
		card_instance.set_card_data(card_data)
		card_instance.card_clicked.connect(_on_card_clicked)
		
		if card_instance.has_signal("mouse_entered"):
			card_instance.mouse_entered.connect(_on_card_hover)
		
		hand_container.add_child(card_instance)
		card_instances.append(card_instance)
		
		var can_play = is_player_turn and player.can_play_card(card_data)
		card_instance.set_playable(can_play)
	
	selected_card_index = clamp(selected_card_index, 0, max(0, card_instances.size() - 1))
	update_card_selection()
	controls_panel.update_cards_available(card_instances.size() > 0)

func update_card_selection():
	if not gamepad_mode or not is_player_turn:
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

func _on_card_hover():
	if not gamepad_mode:
		play_safe_audio("play_card_hover_sound")

func _on_card_clicked(card: Card):
	if not is_player_turn:
		return
	
	if player.can_play_card(card.card_data):
		play_safe_audio("play_card_play_sound", [card.card_data.card_type])
		
		match card.card_data.card_type:
			"attack":
				player.play_card(card.card_data, ai)
			"heal", "shield":
				player.play_card(card.card_data)

func start_player_turn():
	is_player_turn = true
	gamepad_mode = last_input_was_gamepad
	
	play_safe_audio("play_turn_change_sound", [true])
	
	var tween = create_tween()
	tween.tween_property(top_panel_bg, "color", player_turn_color, transition_time)
	
	player.start_turn()
	var max_cards = player.get_max_cards_per_turn()
	var cards_played = player.get_cards_played()
	
	turn_label.text = "Tu turno"
	
	var difficulty_name = difficulty.to_upper()
	game_info_label.text = "Cartas: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty_name
	
	update_turn_button_text()
	update_damage_bonus_indicator()
	
	if end_turn_button:
		end_turn_button.disabled = false
		if gamepad_mode:
			end_turn_button.grab_focus()
	
	selected_card_index = 0
	update_card_selection()

func start_ai_turn():
	is_player_turn = false
	gamepad_mode = false
	
	controls_panel.force_hide()
	
	play_safe_audio("play_turn_change_sound", [false])
	
	var tween = create_tween()
	tween.tween_property(top_panel_bg, "color", ai_turn_color, transition_time)
	
	ai.start_turn()
	turn_label.text = "Turno de la IA"
	game_info_label.text = "La IA está jugando..."
	
	update_damage_bonus_indicator()
	
	if end_turn_button:
		end_turn_button.disabled = true
		end_turn_button.release_focus()
	
	update_hand_display()
	
	await ai.ai_turn(player)
	
	if DeckManager.should_restart_game(player.get_deck_size(), ai.get_deck_size(), player.get_hand_size(), ai.get_hand_size()):
		turn_label.text = "¡Ambos sin cartas!"
		game_info_label.text = "Reiniciando partida..."
		await get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
		restart_game()
		return
	
	await get_tree().create_timer(1.0).timeout
	start_player_turn()

func update_turn_button_text():
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

func _on_end_turn_pressed():
	if is_player_turn and end_turn_button:
		end_turn_button.release_focus()
		
		play_safe_audio("play_notification_sound")
		
		if DeckManager.should_restart_game(player.get_deck_size(), ai.get_deck_size(), player.get_hand_size(), ai.get_hand_size()):
			turn_label.text = "¡Ambos sin cartas!"
			game_info_label.text = "Reiniciando partida..."
			await get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
			restart_game()
			return
		
		start_ai_turn()

func _on_player_hp_changed(new_hp: int):
	player_hp_label.text = str(new_hp)

func _on_player_mana_changed(new_mana: int):
	player_mana_label.text = str(new_mana)

func _on_player_shield_changed(new_shield: int):
	player_shield_label.text = str(new_shield)

func _on_ai_hp_changed(new_hp: int):
	ai_hp_label.text = str(new_hp)

func _on_ai_mana_changed(new_mana: int):
	ai_mana_label.text = str(new_mana)

func _on_ai_shield_changed(new_shield: int):
	ai_shield_label.text = str(new_shield)

func _on_player_cards_played_changed(cards_played: int, max_cards: int):
	update_hand_display()
	update_turn_button_text()
	
	var difficulty_name = difficulty.to_upper()
	game_info_label.text = "Cartas: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty_name
	
	if cards_played >= max_cards:
		turn_label.text = "¡Límite alcanzado!"
		game_info_label.text = "Terminando turno automáticamente..."
		await get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout
		start_ai_turn()
	elif is_player_turn and player.get_hand_size() == 0:
		turn_label.text = "¡Sin cartas!"
		game_info_label.text = "Terminando turno automáticamente..."
		await get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout
		start_ai_turn()

func _on_ai_cards_played_changed(cards_played: int, max_cards: int):
	update_all_labels()

func _on_player_turn_changed(turn_num: int, damage_bonus: int):
	if damage_bonus > 0 and GameBalance.is_damage_bonus_turn(turn_num):
		play_safe_audio("play_bonus_sound")
		
		if game_notification:
			game_notification.show_damage_bonus_notification(turn_num, damage_bonus)
	elif damage_bonus > 0:
		turn_label.text = "Turno " + str(turn_num)
		game_info_label.text = "¡Bonus de daño: +" + str(damage_bonus) + "!"
	
	update_all_labels()
	update_damage_bonus_indicator()

func _on_ai_turn_changed(turn_num: int, damage_bonus: int):
	update_all_labels()
	update_damage_bonus_indicator()

func _on_ai_card_played(card: CardData):
	play_safe_audio("play_card_play_sound", [card.card_type])
	
	if ai_notification:
		ai_notification.show_card_notification(card, "IA")

func _on_player_card_drawn(cards_count: int, from_deck: bool):
	play_safe_audio("play_card_draw_sound")
	
	if game_notification:
		game_notification.show_card_draw_notification("Jugador", cards_count, from_deck)

func _on_player_deck_reshuffled():
	play_safe_audio("play_deck_shuffle_sound")
	
	if game_notification:
		var cards_reshuffled = player.deck.size()
		game_notification.show_reshuffle_notification("Jugador", cards_reshuffled)
	turn_label.text = "¡Remezcla de cartas"
	game_info_label.text = "Cartas devueltas al mazo"
	await get_tree().create_timer(2.0).timeout

func _on_ai_deck_reshuffled():
	play_safe_audio("play_deck_shuffle_sound")
	
	turn_label.text = "IA remezcló"
	game_info_label.text = "Algunas cartas volvieron a su al mazo"
	await get_tree().create_timer(2.0).timeout

func _on_player_auto_turn_ended(reason: String):
	if game_notification:
		game_notification.show_auto_end_turn_notification(reason)

func _on_player_hand_changed():
	update_hand_display()
	update_turn_button_text()
	
	if is_player_turn and player.get_hand_size() == 0:
		turn_label.text = "¡Sin cartas!"
		game_info_label.text = "Terminando turno automáticamente..."
		await get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout
		start_ai_turn()

func _on_ai_hand_changed():
	update_all_labels()

func _on_player_deck_empty():
	if player.discard_pile.size() == 0:
		turn_label.text = "¡Sin cartas!"
		game_info_label.text = "Verificando reinicio..."

func _on_ai_deck_empty():
	if ai.discard_pile.size() == 0:
		turn_label.text = "IA sin cartas"
		game_info_label.text = "Verificando reinicio..."

func _on_player_died():
	play_safe_audio("play_lose_sound")
	
	GameState.add_game_result(false)
	
	if game_notification:
		game_notification.show_game_end_notification("Derrota", "hp_zero")
	game_over_label.text = "¡PERDISTE! Reiniciando..."
	game_over_label.visible = true
	if end_turn_button:
		end_turn_button.disabled = true
	await get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
	restart_game()

func _on_ai_died():
	play_safe_audio("play_win_sound")

	GameState.add_game_result(true)
	
	if game_notification:
		game_notification.show_game_end_notification("¡Victoria!", "hp_zero")
	game_over_label.text = "¡GANASTE! Reiniciando..."
	game_over_label.visible = true
	if end_turn_button:
		end_turn_button.disabled = true
	await get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
	restart_game()

func _input(event):
	if is_showing_confirmation:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("gamepad_accept"):
			if confirm_button.has_focus():
				_on_confirm_exit()
			elif cancel_button.has_focus():
				_on_cancel_exit()
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("gamepad_cancel"):
			_on_cancel_exit()
		elif event.is_action_pressed("ui_left"):
			confirm_button.grab_focus()
		elif event.is_action_pressed("ui_right"):
			cancel_button.grab_focus()
		return
	
	if event.is_action_pressed("gamepad_start"):
		if controls_panel and is_player_turn:
			controls_panel.toggle_visibility()
			play_safe_audio("play_card_hover_sound")
		return

	if event is InputEventJoypadButton and event.pressed:
		if not last_input_was_gamepad:
			last_input_was_gamepad = true
			if is_player_turn and player:
				gamepad_mode = true
				update_card_selection()
				update_turn_button_text()
				if controls_panel:
					controls_panel.update_gamepad_mode(true)
	elif event is InputEventMouse or (event is InputEventKey and event.pressed):
		if last_input_was_gamepad:
			last_input_was_gamepad = false
			if is_player_turn and player:
				gamepad_mode = false
				update_card_selection()
				update_turn_button_text()
				if controls_panel:
					controls_panel.update_gamepad_mode(false)
   
	if event.is_action_pressed("restart_game") or event.is_action_pressed("gamepad_restart"):
		restart_game()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("gamepad_exit"):
		show_exit_confirmation()
	elif is_player_turn and gamepad_mode and player:
		if event.is_action_pressed("ui_left"):
			if card_instances.size() > 0:
				selected_card_index = (selected_card_index - 1) % card_instances.size()
				update_card_selection()
				play_safe_audio("play_card_hover_sound")
		elif event.is_action_pressed("ui_right"):
			if card_instances.size() > 0:
				selected_card_index = (selected_card_index + 1) % card_instances.size()
				update_card_selection()
				play_safe_audio("play_card_hover_sound")
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("gamepad_accept"):
			if card_instances.size() > 0 and selected_card_index < card_instances.size():
				var selected_card = card_instances[selected_card_index]
				_on_card_clicked(selected_card)
		elif event.is_action_pressed("gamepad_cancel"):
			if end_turn_button and not end_turn_button.disabled:
				_on_end_turn_pressed()

func _on_player_damage_taken(damage_amount: int):
	play_safe_audio("play_damage_sound", [damage_amount])
   
	play_damage_effects(damage_amount)

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
   	
		var tween = create_tween()
		tween.tween_property(ui_layer, "position", shake_position, time_per_shake)
		await tween.finished
   
	var final_tween = create_tween()
	final_tween.tween_property(ui_layer, "position", original_ui_position, 0.1)
	await final_tween.finished
   
	is_screen_shaking = false

func return_to_menu():
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 1.0)
