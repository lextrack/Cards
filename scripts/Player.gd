class_name Player
extends Node

@export var difficulty: String = "normal"
@export var is_ai: bool = false

var max_hp: int
var max_mana: int
var max_hand_size: int
var max_cards_per_turn: int

var current_hp: int
var current_mana: int
var current_shield: int = 0
var hand: Array = []
var deck: Array = []
var discard_pile: Array = []
var cards_played_this_turn: int = 0
var turn_number: int = 0

signal hp_changed(new_hp: int)
signal mana_changed(new_mana: int)
signal shield_changed(new_shield: int)
signal player_died
signal hand_changed
signal deck_empty
signal deck_reshuffled
signal cards_played_changed(cards_played: int, max_cards: int)
signal turn_changed(turn_num: int, damage_bonus: int)
signal ai_card_played(card: CardData)
signal card_drawn(cards_count: int, from_deck: bool)
signal auto_turn_ended(reason: String)
signal damage_taken(damage_amount: int)

func _ready():
	setup_from_difficulty()
	if is_ai:
		deck = DeckManager.create_basic_deck()
	else:
		deck = create_player_deck_by_difficulty()
	draw_initial_hand()
	
func create_player_deck_by_difficulty() -> Array:
	var distribution = GameBalance.get_card_distribution(difficulty)
	return CardProbability.create_balanced_deck(30, distribution.attack_ratio, distribution.heal_ratio, distribution.shield_ratio)

func setup_from_difficulty():
	GameBalance.setup_player(self, difficulty, is_ai)
	var config = GameBalance.get_ai_config(difficulty) if is_ai else GameBalance.get_player_config(difficulty)
	max_cards_per_turn = config.cards_per_turn

func get_max_cards_per_turn() -> int:
	return max_cards_per_turn

func get_damage_bonus() -> int:
	return GameBalance.get_damage_bonus(turn_number)

func draw_initial_hand():
	for i in range(max_hand_size):
		draw_card()
	card_drawn.emit(max_hand_size, false)

func draw_card() -> bool:
	if deck.size() == 0 and discard_pile.size() > 0:
		var cards_to_reshuffle = discard_pile.size()
		deck = DeckManager.create_discard_pile_deck(discard_pile)
		discard_pile.clear()
		deck_reshuffled.emit()
	
	if deck.size() > 0 and hand.size() < max_hand_size:
		hand.append(deck.pop_back())
		hand_changed.emit()
		if not is_ai:
			card_drawn.emit(1, true)
		return true
	elif deck.size() == 0 and discard_pile.size() == 0:
		deck_empty.emit()
		return false
	return false

func take_damage(damage: int):
	var actual_damage = max(0, damage - current_shield)
	current_shield = max(0, current_shield - damage)
	current_hp -= actual_damage
	
	if actual_damage > 0:
		damage_taken.emit(actual_damage)
	
	if current_hp <= 0:
		current_hp = 0
		player_died.emit()
	
	hp_changed.emit(current_hp)
	shield_changed.emit(current_shield)

func heal(amount: int):
	current_hp += amount
	hp_changed.emit(current_hp)

func add_shield(amount: int):
	current_shield += amount
	shield_changed.emit(current_shield)

func spend_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana)
		return true
	return false

func start_turn():
	turn_number += 1
	current_mana = max_mana
	cards_played_this_turn = 0
	draw_card()
	mana_changed.emit(current_mana)
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	turn_changed.emit(turn_number, get_damage_bonus())

func can_play_card(card: CardData) -> bool:
	var has_mana = current_mana >= card.cost
	var can_play_more_cards = cards_played_this_turn < get_max_cards_per_turn()
	return has_mana and can_play_more_cards

func play_card(card: CardData, target: Player = null) -> bool:
	if not can_play_card(card):
		return false
	
	spend_mana(card.cost)
	hand.erase(card)
	discard_pile.append(card)
	cards_played_this_turn += 1
	
	hand_changed.emit()
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	
	match card.card_type:
		"attack":
			if target:
				var bonus_damage = get_damage_bonus()
				var total_damage = card.damage + bonus_damage
				target.take_damage(total_damage)
		"heal":
			heal(card.heal)
		"shield":
			add_shield(card.shield)
	
	return true

func get_hand_size() -> int:
	return hand.size()

func get_deck_size() -> int:
	return deck.size()

func get_total_cards() -> int:
	return deck.size() + discard_pile.size()

func get_cards_played() -> int:
	return cards_played_this_turn

func can_play_more_cards() -> bool:
	return cards_played_this_turn < get_max_cards_per_turn()

func set_difficulty(new_difficulty: String):
	difficulty = new_difficulty
	setup_from_difficulty()

func reset_player():
	setup_from_difficulty()
	
	current_hp = max_hp
	current_mana = max_mana
	current_shield = 0
	cards_played_this_turn = 0
	turn_number = 0
	hand.clear()
	discard_pile.clear()
	deck = DeckManager.create_basic_deck()
	draw_initial_hand()
	
	hp_changed.emit(current_hp)
	mana_changed.emit(current_mana)
	shield_changed.emit(current_shield)
	hand_changed.emit()
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	turn_changed.emit(turn_number, get_damage_bonus())

func ai_turn(opponent: Player):
	if not is_ai:
		return
	
	await get_tree().create_timer(GameBalance.get_timer_delay("ai_turn_start")).timeout
	
	var ai_config = GameBalance.get_ai_config(difficulty)
	var heal_threshold = ai_config.get("heal_threshold", 0.3)
	var aggression = ai_config.get("aggression", 0.5)
	
	while can_play_more_cards():
		var playable_cards = DeckManager.get_playable_cards(hand, current_mana)
		
		if playable_cards.size() == 0:
			break
		
		var chosen_card: CardData = null
		
		# Estrategia de finisher: si el oponente tiene poca vida, buscar golpe final
		if opponent.current_hp <= 12:
			var finisher_cards = []
			for card in playable_cards:
				if card.card_type == "attack" and card.damage >= 10:
					finisher_cards.append(card)
			if finisher_cards.size() > 0:
				chosen_card = finisher_cards[0]
		
		# Estrategia de curación: si la IA tiene poca vida, priorizar curación
		if not chosen_card and current_hp < max_hp * heal_threshold:
			var heal_cards = DeckManager.get_cards_by_type(playable_cards, "heal")
			if heal_cards.size() > 0:
				chosen_card = heal_cards[0]
		
		# Estrategia defensiva: si no tiene escudo y el oponente puede atacar fuerte
		if not chosen_card and current_shield == 0 and opponent.current_mana >= 4 and randf() > aggression:
			var shield_cards = DeckManager.get_cards_by_type(playable_cards, "shield")
			if shield_cards.size() > 0:
				chosen_card = shield_cards[0]
		
		# Estrategia ofensiva: atacar con la carta más fuerte
		if not chosen_card:
			chosen_card = DeckManager.get_strongest_attack_card(playable_cards)
		
		# Fallback: tomar cualquier carta
		if not chosen_card:
			chosen_card = playable_cards[0]
		
		if chosen_card:
			ai_card_played.emit(chosen_card)
			
			await get_tree().create_timer(GameBalance.get_timer_delay("ai_card_notification")).timeout
			
			match chosen_card.card_type:
				"attack":
					play_card(chosen_card, opponent)
				"heal", "shield":
					play_card(chosen_card)
			
			await get_tree().create_timer(GameBalance.get_timer_delay("ai_card_play")).timeout
		else:
			break
