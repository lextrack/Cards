class_name DeckManager
extends RefCounted

static func create_basic_deck() -> Array:
	# Usar el nuevo sistema de probabilidades
	return CardProbability.create_balanced_deck(30, 0.8)  # 30 cartas, 80% ataques

static func create_random_deck() -> Array:
	# Mazo completamente aleatorio basado en pesos
	return CardProbability.create_weighted_deck(30)

static func create_discard_pile_deck(discard_pile: Array) -> Array:
	# Crea un nuevo mazo a partir del cementerio
	var new_deck = discard_pile.duplicate()
	new_deck.shuffle()
	return new_deck

static func get_playable_cards(hand: Array, current_mana: int) -> Array:
	var playable = []
	for card in hand:
		if card is CardData and card.cost <= current_mana:
			playable.append(card)
	return playable

static func get_cards_by_type(cards: Array, type: String) -> Array:
	var filtered = []
	for card in cards:
		if card is CardData and card.card_type == type:
			filtered.append(card)
	return filtered

static func get_strongest_attack_card(cards: Array) -> CardData:
	var attack_cards = get_cards_by_type(cards, "attack")
	if attack_cards.size() == 0:
		return null
	
	var strongest = attack_cards[0]
	for card in attack_cards:
		if card.damage > strongest.damage:
			strongest = card
	
	return strongest

static func should_restart_game(player_deck_size: int, ai_deck_size: int, player_hand_size: int, ai_hand_size: int) -> bool:
	# Reiniciar si ambos jugadores no tienen cartas (ni en mazo ni en mano)
	var player_no_cards = player_deck_size == 0 and player_hand_size == 0
	var ai_no_cards = ai_deck_size == 0 and ai_hand_size == 0
	return player_no_cards and ai_no_cards

static func calculate_damage_bonus(turn_number: int) -> int:
	# Bonus de daño progresivo para acelerar partidas
	if turn_number >= 12:
		return 2  # +2 daño después del turno 12
	elif turn_number >= 6:
		return 1  # +1 daño después del turno 6
	else:
		return 0  # Sin bonus los primeros 6 turnos

# Nuevas funciones para estadísticas
static func print_deck_stats(deck: Array, player_name: String = "Jugador"):
	var stats = CardProbability.get_deck_stats(deck)
	print("\n=== Estadísticas de " + player_name + " ===")
	print("Total de cartas: " + str(stats.total_cards))
	print("Ataques: " + str(stats.attack_cards) + " (" + str(int(stats.attack_cards * 100.0 / stats.total_cards)) + "%)")
	print("Curaciones: " + str(stats.heal_cards) + " (" + str(int(stats.heal_cards * 100.0 / stats.total_cards)) + "%)")
	print("Escudos: " + str(stats.shield_cards) + " (" + str(int(stats.shield_cards * 100.0 / stats.total_cards)) + "%)")
	print("\nRareza:")
	print("Comunes: " + str(stats.common))
	print("Poco comunes: " + str(stats.uncommon))
	print("Raras: " + str(stats.rare))
	print("Épicas: " + str(stats.epic))

static func get_card_rarity_text(card: CardData) -> String:
	var rarity = CardProbability.calculate_card_rarity(card.damage, card.heal, card.shield)
	match rarity:
		"common":
			return "[Común]"
		"uncommon":
			return "[Poco Común]"
		"rare":
			return "[Rara]"
		"epic":
			return "[ÉPICA]"
		_:
			return ""
