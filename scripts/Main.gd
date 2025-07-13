extends Control

@onready var player_hp_label = $VBox/PlayerStats/HPLabel
@onready var player_mana_label = $VBox/PlayerStats/ManaLabel
@onready var player_shield_label = $VBox/PlayerStats/ShieldLabel

@onready var ai_hp_label = $VBox/AIStats/HPLabel
@onready var ai_mana_label = $VBox/AIStats/ManaLabel
@onready var ai_shield_label = $VBox/AIStats/ShieldLabel

@onready var hand_container = $VBox/HandContainer
@onready var turn_label = $VBox/TurnLabel
@onready var pass_turn_button = $VBox/TurnButtonsContainer/PassTurnButton
@onready var end_turn_button = $VBox/TurnButtonsContainer/EndTurnButton
@onready var game_over_label = $VBox/GameOverLabel

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

func _ready():
	# Conectar botones
	pass_turn_button.pressed.connect(_on_pass_turn_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	ai_notification = ai_notification_scene.instantiate()
	add_child(ai_notification)
	
	game_notification = game_notification_scene.instantiate()
	add_child(game_notification)
	
	setup_game()

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
	
	GameBalance.print_current_config(difficulty)
	
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
	turn_label.text = "¡Nueva partida! (Partida #" + str(game_count) + ")"
	await get_tree().create_timer(GameBalance.get_timer_delay("new_game")).timeout
	setup_game()

func set_difficulty(new_difficulty: String):
	difficulty = new_difficulty
	if player:
		player.set_difficulty(difficulty)
	if ai:
		ai.set_difficulty(difficulty)
	update_all_labels()
	
	var description = GameBalance.get_difficulty_description(difficulty)
	turn_label.text = difficulty.to_upper() + ": " + description

func update_all_labels():
	var difficulty_text = " [" + difficulty.to_upper() + "]"
	var damage_bonus = player.get_damage_bonus()
	var bonus_text = ""
	if damage_bonus > 0:
		bonus_text = " (+{0} dmg)".format([damage_bonus])
	
	player_hp_label.text = "HP: " + str(player.current_hp)
	player_mana_label.text = "Maná: " + str(player.current_mana)
	player_shield_label.text = "Escudo: " + str(player.current_shield) + " | Cartas: " + str(player.get_hand_size()) + "/" + str(player.get_total_cards()) + " | Jugadas: " + str(player.get_cards_played()) + "/" + str(player.get_max_cards_per_turn()) + difficulty_text + bonus_text
	
	ai_hp_label.text = "IA HP: " + str(ai.current_hp)
	ai_mana_label.text = "IA Maná: " + str(ai.current_mana)
	ai_shield_label.text = "IA Escudo: " + str(ai.current_shield) + " | Cartas: " + str(ai.get_hand_size()) + "/" + str(ai.get_total_cards()) + " | Jugadas: " + str(ai.get_cards_played()) + "/" + str(ai.get_max_cards_per_turn()) + bonus_text

func update_hand_display():
	for child in hand_container.get_children():
		child.queue_free()
	
	for card_data in player.hand:
		var card_instance = card_scene.instantiate()
		card_instance.set_card_data(card_data)
		card_instance.card_clicked.connect(_on_card_clicked)
		hand_container.add_child(card_instance)
		
		if not player.can_play_card(card_data):
			card_instance.modulate = Color(0.5, 0.5, 0.5, 1.0)

func _on_card_clicked(card: Card):
	if not is_player_turn:
		return
	
	if player.can_play_card(card.card_data):
		match card.card_data.card_type:
			"attack":
				player.play_card(card.card_data, ai)
			"heal", "shield":
				player.play_card(card.card_data)

func start_player_turn():
	is_player_turn = true
	player.start_turn()
	var max_cards = player.get_max_cards_per_turn()
	turn_label.text = "Tu turno - Puedes jugar " + str(max_cards) + " carta" + ("s" if max_cards > 1 else "")
	
	# Habilitar ambos botones
	pass_turn_button.disabled = false
	end_turn_button.disabled = false

func start_ai_turn():
	is_player_turn = false
	ai.start_turn()
	turn_label.text = "Turno de la IA"
	
	# Deshabilitar ambos botones
	pass_turn_button.disabled = true
	end_turn_button.disabled = true
	
	await ai.ai_turn(player)
	
	if DeckManager.should_restart_game(player.get_deck_size(), ai.get_deck_size(), player.get_hand_size(), ai.get_hand_size()):
		turn_label.text = "¡Ambos sin cartas! Reiniciando..."
		await get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
		restart_game()
		return
	
	await get_tree().create_timer(1.0).timeout
	start_player_turn()

# Nuevo: Función para pasar turno sin jugar cartas
func _on_pass_turn_pressed():
	if is_player_turn:
		turn_label.text = "Pasaste el turno - Sin cartas jugadas"
		
		# Mostrar notificación de turno pasado
		if game_notification:
			game_notification.show_auto_end_turn_notification("pass_turn")
		
		await get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout
		
		if DeckManager.should_restart_game(player.get_deck_size(), ai.get_deck_size(), player.get_hand_size(), ai.get_hand_size()):
			turn_label.text = "¡Ambos sin cartas! Reiniciando..."
			await get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
			restart_game()
			return
		
		start_ai_turn()

func _on_end_turn_pressed():
	if is_player_turn:
		if DeckManager.should_restart_game(player.get_deck_size(), ai.get_deck_size(), player.get_hand_size(), ai.get_hand_size()):
			turn_label.text = "¡Ambos sin cartas! Reiniciando..."
			await get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
			restart_game()
			return
		
		start_ai_turn()

func _on_player_hp_changed(new_hp: int):
	player_hp_label.text = "HP: " + str(new_hp)

func _on_player_mana_changed(new_mana: int):
	player_mana_label.text = "Maná: " + str(new_mana)

func _on_player_shield_changed(new_shield: int):
	update_all_labels()

func _on_ai_hp_changed(new_hp: int):
	ai_hp_label.text = "IA HP: " + str(new_hp)

func _on_ai_mana_changed(new_mana: int):
	ai_mana_label.text = "IA Maná: " + str(new_mana)

func _on_ai_shield_changed(new_shield: int):
	update_all_labels()

func _on_player_cards_played_changed(cards_played: int, max_cards: int):
	update_all_labels()
	update_hand_display()
	
	if cards_played >= max_cards:
		turn_label.text = "¡Límite alcanzado! Terminando turno..."
		await get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout
		start_ai_turn()
	elif is_player_turn and player.get_hand_size() == 0:
		turn_label.text = "¡Sin cartas! Terminando turno..."
		await get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout
		start_ai_turn()

func _on_ai_cards_played_changed(cards_played: int, max_cards: int):
	update_all_labels()

func _on_player_turn_changed(turn_num: int, damage_bonus: int):
	if damage_bonus > 0 and GameBalance.is_damage_bonus_turn(turn_num):
		if game_notification:
			game_notification.show_damage_bonus_notification(turn_num, damage_bonus)
	elif damage_bonus > 0:
		turn_label.text = "Turno " + str(turn_num) + " - ¡Bonus de daño: +" + str(damage_bonus) + "!"
	update_all_labels()

func _on_ai_turn_changed(turn_num: int, damage_bonus: int):
	update_all_labels()

func _on_ai_card_played(card: CardData):
	if ai_notification:
		ai_notification.show_card_notification(card, "IA")

func _on_player_card_drawn(cards_count: int, from_deck: bool):
	if game_notification:
		game_notification.show_card_draw_notification("Jugador", cards_count, from_deck)

func _on_player_deck_reshuffled():
	if game_notification:
		var cards_reshuffled = player.deck.size()
		game_notification.show_reshuffle_notification("Jugador", cards_reshuffled)
	turn_label.text = "¡Tu cementerio se remezcló en el mazo!"
	await get_tree().create_timer(2.0).timeout

func _on_ai_deck_reshuffled():
	turn_label.text = "La IA remezcló su cementerio"
	await get_tree().create_timer(2.0).timeout

func _on_player_auto_turn_ended(reason: String):
	if game_notification:
		game_notification.show_auto_end_turn_notification(reason)

func _on_player_hand_changed():
	update_hand_display()
	update_all_labels()
	
	if is_player_turn and player.get_hand_size() == 0:
		turn_label.text = "¡Sin cartas! Terminando turno..."
		await get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout
		start_ai_turn()

func _on_ai_hand_changed():
	update_all_labels()

func _on_player_deck_empty():
	if player.discard_pile.size() == 0:
		turn_label.text = "¡Sin cartas! Verificando reinicio..."

func _on_ai_deck_empty():
	if ai.discard_pile.size() == 0:
		turn_label.text = "IA sin cartas - Verificando reinicio..."

func _on_player_died():
	if game_notification:
		game_notification.show_game_end_notification("Derrota", "hp_zero")
	game_over_label.text = "¡Perdiste! Reiniciando en " + str(int(GameBalance.get_timer_delay("death_restart"))) + " segundo..."
	game_over_label.visible = true
	pass_turn_button.disabled = true
	end_turn_button.disabled = true
	await get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
	restart_game()

func _on_ai_died():
	if game_notification:
		game_notification.show_game_end_notification("Victoria", "hp_zero")
	game_over_label.text = "¡Ganaste! Reiniciando en " + str(int(GameBalance.get_timer_delay("death_restart"))) + " segundo..."
	game_over_label.visible = true
	pass_turn_button.disabled = true
	end_turn_button.disabled = true
	await get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
	restart_game()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		var difficulties = GameBalance.get_available_difficulties()
		var current_index = difficulties.find(difficulty)
		var next_index = (current_index + 1) % difficulties.size()
		set_difficulty(difficulties[next_index])
	elif event.is_action_pressed("restart_game"):
		restart_game()
