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

func _ready():
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
	else:
		push_error("EndTurnButton no encontrado en la escena")
	
	original_ui_position = ui_layer.position
	
	ai_notification = ai_notification_scene.instantiate()
	add_child(ai_notification)
	
	game_notification = game_notification_scene.instantiate()
	add_child(game_notification)
	
	await handle_scene_entrance()
	
	setup_game()
	
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

	# Conectar señales del jugador
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
	
	# Conectar señales de la IA
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
	game_info_label.text = "Partida #" + str(game_count)
	
	play_safe_audio("play_background_music")
	
	await get_tree().create_timer(GameBalance.get_timer_delay("new_game")).timeout
	setup_game()

func set_difficulty(new_difficulty: String):
	var old_difficulty = difficulty
	difficulty = new_difficulty
	
	# 🔊 Sonido de cambio de configuración
	play_safe_audio("play_notification_sound")
	
	if player and ai:
		player.change_difficulty_safe(difficulty)
		ai.change_difficulty_safe(difficulty)
		
		var description = GameBalance.get_difficulty_description(difficulty)
		turn_label.text = "Dificultad: " + difficulty.to_upper()
		game_info_label.text = description
		
		update_all_labels()
		update_hand_display()
	else:
		var description = GameBalance.get_difficulty_description(difficulty)
		turn_label.text = difficulty.to_upper()
		game_info_label.text = description

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
	
	for card_data in player.hand:
		var card_instance = card_scene.instantiate()
		card_instance.set_card_data(card_data)
		card_instance.card_clicked.connect(_on_card_clicked)
		
		# 🔊 Conectar sonido de hover a las cartas
		if card_instance.has_signal("mouse_entered"):
			card_instance.mouse_entered.connect(_on_card_hover)
		
		hand_container.add_child(card_instance)
		
		var can_play = is_player_turn and player.can_play_card(card_data)
		card_instance.set_playable(can_play)

func _on_card_hover():
	# 🔊 Sonido al pasar el mouse sobre las cartas
	play_safe_audio("play_card_hover_sound")

func _on_card_clicked(card: Card):
	if not is_player_turn:
		return
	
	if player.can_play_card(card.card_data):
		# 🔊 Sonido al jugar carta según su tipo
		play_safe_audio("play_card_play_sound", [card.card_data.card_type])
		
		match card.card_data.card_type:
			"attack":
				player.play_card(card.card_data, ai)
			"heal", "shield":
				player.play_card(card.card_data)

func start_player_turn():
	is_player_turn = true
	
	# 🔊 Sonido de cambio de turno
	play_safe_audio("play_turn_change_sound", [true])
	
	var tween = create_tween()
	tween.tween_property(top_panel_bg, "color", player_turn_color, transition_time)
	
	player.start_turn()
	var max_cards = player.get_max_cards_per_turn()
	var cards_played = player.get_cards_played()
	
	turn_label.text = "Tu turno"
	game_info_label.text = "Cartas: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty.to_upper() + " | [ENTER] cambiar dificultad"
	
	update_turn_button_text()
	update_damage_bonus_indicator()
	
	if end_turn_button:
		end_turn_button.disabled = false

func start_ai_turn():
	is_player_turn = false
	
	# 🔊 Sonido de cambio de turno (IA)
	play_safe_audio("play_turn_change_sound", [false])
	
	var tween = create_tween()
	tween.tween_property(top_panel_bg, "color", ai_turn_color, transition_time)
	
	ai.start_turn()
	turn_label.text = "Turno de la IA"
	game_info_label.text = "La IA está jugando..."
	
	update_damage_bonus_indicator() 
	
	if end_turn_button:
		end_turn_button.disabled = true
	
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
	if not end_turn_button:
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
		end_turn_button.text = "Terminar Turno"

func _on_end_turn_pressed():
	if is_player_turn and end_turn_button:
		end_turn_button.release_focus()
		
		# 🔊 Sonido de botón UI
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
	game_info_label.text = "Cartas: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty.to_upper() + " | [ENTER] cambiar dificultad"
	
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
		# 🔊 Sonido especial de bonus
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
	# 🔊 Sonido cuando la IA juega carta
	play_safe_audio("play_card_play_sound", [card.card_type])
	
	if ai_notification:
		ai_notification.show_card_notification(card, "IA")

func _on_player_card_drawn(cards_count: int, from_deck: bool):
	# 🔊 Sonido de robar cartas
	play_safe_audio("play_card_draw_sound")
	
	if game_notification:
		game_notification.show_card_draw_notification("Jugador", cards_count, from_deck)

func _on_player_deck_reshuffled():
	# 🔊 Sonido de barajar cartas
	play_safe_audio("play_deck_shuffle_sound")
	
	if game_notification:
		var cards_reshuffled = player.deck.size()
		game_notification.show_reshuffle_notification("Jugador", cards_reshuffled)
	turn_label.text = "¡Remezcla de cartas"
	game_info_label.text = "Cartas devueltas al mazo"
	await get_tree().create_timer(2.0).timeout

func _on_ai_deck_reshuffled():
	# 🔊 Sonido de barajar cartas (IA)
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
	# 🔊 Sonido de derrota
	play_safe_audio("play_lose_sound")
	
	if game_notification:
		game_notification.show_game_end_notification("Derrota", "hp_zero")
	game_over_label.text = "¡PERDISTE! Reiniciando..."
	game_over_label.visible = true
	if end_turn_button:
		end_turn_button.disabled = true
	await get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
	restart_game()

func _on_ai_died():
	# 🔊 Sonido de victoria
	play_safe_audio("play_win_sound")
	
	if game_notification:
		game_notification.show_game_end_notification("Victoria", "hp_zero")
	game_over_label.text = "¡GANASTE! Reiniciando..."
	game_over_label.visible = true
	if end_turn_button:
		end_turn_button.disabled = true
	await get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
	restart_game()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if is_player_turn:
			var difficulties = GameBalance.get_available_difficulties()
			var current_index = difficulties.find(difficulty)
			var next_index = (current_index + 1) % difficulties.size()
			set_difficulty(difficulties[next_index])
		else:
			turn_label.text = "Turno de la IA"
			game_info_label.text = "No puedes cambiar dificultad ahora"
	elif event.is_action_pressed("restart_game"):
		restart_game()
	elif event.is_action_pressed("ui_cancel"):
		# ESC para volver al menú
		return_to_menu()

func _on_player_damage_taken(damage_amount: int):
	# 🔊 Sonido de recibir daño
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
	"""Vuelve al menú principal con transición suave"""
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 1.0, "Volviendo al menú...")
