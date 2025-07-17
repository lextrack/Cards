class_name GameManager
extends RefCounted

var main_scene: Control
var player: Player
var ai: Player

func setup(main: Control):
	main_scene = main

func setup_new_game(difficulty: String):
	"""Configura una nueva partida"""
	if player:
		player.queue_free()
	if ai:
		ai.queue_free()
	
	player = Player.new()
	ai = Player.new()
	ai.is_ai = true
	
	player.difficulty = difficulty
	ai.difficulty = difficulty
	
	main_scene.add_child(player)
	main_scene.add_child(ai)
	
	main_scene.game_over_label.visible = false

func restart_game(game_count: int, difficulty: String):
	"""Reinicia el juego con un nuevo contador"""
	main_scene.turn_label.text = "¡Nueva partida!"
	main_scene.ui_manager.selected_card_index = 0
	
	var difficulty_desc = GameBalance.get_difficulty_description(difficulty)
	main_scene.game_info_label.text = "Partida #" + str(game_count) + " | " + difficulty.to_upper()

func should_restart_for_no_cards() -> bool:
	"""Verifica si se debe reiniciar por falta de cartas"""
	return DeckManager.should_restart_game(
		player.get_deck_size(), 
		ai.get_deck_size(), 
		player.get_hand_size(), 
		ai.get_hand_size()
	)

func restart_for_no_cards():
	"""Maneja el reinicio cuando ambos jugadores se quedan sin cartas"""
	main_scene.turn_label.text = "¡Ambos sin cartas!"
	main_scene.game_info_label.text = "Reiniciando partida..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
	main_scene.restart_game()

func end_turn_limit_reached():
	"""Maneja el final de turno por límite de cartas alcanzado"""
	main_scene.turn_label.text = "¡Límite alcanzado!"
	main_scene.game_info_label.text = "Terminando turno automáticamente..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func end_turn_no_cards():
	"""Maneja el final de turno por falta de cartas"""
	main_scene.turn_label.text = "¡Sin cartas!"
	main_scene.game_info_label.text = "Terminando turno automáticamente..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func handle_game_over(message: String, end_turn_button: Button):
	"""Maneja el final del juego"""
	main_scene.game_over_label.text = message
	main_scene.game_over_label.visible = true
	if end_turn_button:
		end_turn_button.disabled = true
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
