class_name GameBalance
extends RefCounted

const DEFAULT_MANA: int = 10
const DEFAULT_HAND_SIZE: int = 5
const DEFAULT_DECK_SIZE: int = 30

const DAMAGE_BONUS_TURN_1: int = 6
const DAMAGE_BONUS_TURN_2: int = 12
const DAMAGE_BONUS_TURN_3: int = 18
const DAMAGE_BONUS_TURN_4: int = 25
const DAMAGE_BONUS_1: int = 1
const DAMAGE_BONUS_2: int = 2
const DAMAGE_BONUS_3: int = 3
const DAMAGE_BONUS_4: int = 4

const BASE_TURN_END_DELAY: float = 0.5
const BASE_GAME_RESTART_DELAY: float = 0.8
const BASE_NEW_GAME_DELAY: float = 0.5
const BASE_DEATH_RESTART_DELAY: float = 1.0
const BASE_DECK_RESHUFFLE_NOTIFICATION: float = 1.2
const BASE_AI_TURN_START_DELAY: float = 1.2
const BASE_AI_CARD_NOTIFICATION_DELAY: float = 1.2
const BASE_AI_CARD_PLAY_DELAY: float = 0.8

const AI_CARD_POPUP_DURATION: float = 1.2
const GAME_NOTIFICATION_DRAW_DURATION: float = 1.2
const GAME_NOTIFICATION_RESHUFFLE_DURATION: float = 1.8
const GAME_NOTIFICATION_BONUS_DURATION: float = 2.5
const GAME_NOTIFICATION_END_DURATION: float = 2.5
const GAME_NOTIFICATION_AUTO_TURN_DURATION: float = 1.5

const MIN_HEAL_CARDS: int = 3
const MIN_SHIELD_CARDS: int = 2
const MIN_ATTACK_CARDS: int = 20

enum Difficulty {
	NORMAL,
	HARD,
	EXPERT
}

static func get_player_config(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"hp": 44,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": 4,
				"deck_size": DEFAULT_DECK_SIZE
			}
		"hard":
			return {
				"hp": 44,
				"mana": 11,
				"cards_per_turn": 1,
				"hand_size": 5,
				"deck_size": DEFAULT_DECK_SIZE
			}
		"expert":
			return {
				"hp": 42,
				"mana": 9,
				"cards_per_turn": 1,
				"hand_size": 6,
				"deck_size": 28
			}
		_:
			return get_player_config("normal")

static func get_ai_config(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"hp": 44,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.5,
				"heal_threshold": 0.4
			}
		"hard":
			return {
				"hp": 45,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.6,
				"heal_threshold": 0.35
			}
		"expert":
			return {
				"hp": 45,
				"mana": 11,
				"cards_per_turn": 3,
				"hand_size": 6,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.7,
				"heal_threshold": 0.31
			}
		_:
			return get_ai_config("normal")

static func get_card_distribution(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"attack_ratio": 0.75,
				"heal_ratio": 0.15,
				"shield_ratio": 0.10
			}
		"hard":
			return {
				"attack_ratio": 0.70,
				"heal_ratio": 0.22,
				"shield_ratio": 0.13
			}
		"expert":
			return {
				"attack_ratio": 0.75,
				"heal_ratio": 0.20,
				"shield_ratio": 0.18
			}
		_:
			return get_card_distribution("normal")

static func get_damage_bonus(turn_number: int) -> int:
	if turn_number >= DAMAGE_BONUS_TURN_4:
		return DAMAGE_BONUS_4
	elif turn_number >= DAMAGE_BONUS_TURN_3:
		return DAMAGE_BONUS_3
	elif turn_number >= DAMAGE_BONUS_TURN_2:
		return DAMAGE_BONUS_2
	elif turn_number >= DAMAGE_BONUS_TURN_1:
		return DAMAGE_BONUS_1
	else:
		return 0

static func is_damage_bonus_turn(turn_number: int) -> bool:
	return turn_number == DAMAGE_BONUS_TURN_1 or turn_number == DAMAGE_BONUS_TURN_2 or turn_number == DAMAGE_BONUS_TURN_3 or turn_number == DAMAGE_BONUS_TURN_4

static func get_damage_bonus_description(turn_number: int) -> String:
	var bonus = get_damage_bonus(turn_number)
	match bonus:
		0:
			return "No bonus"
		1:
			return "Damage increased by +1"
		2:
			return "Damage increased by +2"
		3:
			return "Damage increased by +3"
		4:
			return "Damage increased by +4"
		_:
			return "Bonus: +" + str(bonus) + " damage"

static func get_available_difficulties() -> Array:
	return ["normal", "hard", "expert"]

static func get_difficulty_description(difficulty: String) -> String:
	match difficulty:
		"normal":
			return "Balanced"
		"hard":
			return "Challenging"
		"expert":
			return "Brutal"
		_:
			return "Unknown difficulty"

static func setup_player(player: Player, difficulty: String, is_ai: bool = false):
	var config = get_ai_config(difficulty) if is_ai else get_player_config(difficulty)
   
	player.max_hp = config.hp
	player.current_hp = config.hp
	player.max_mana = config.mana
	player.current_mana = config.mana
	player.max_hand_size = config.hand_size
	player.difficulty = difficulty

static func create_balanced_deck_guaranteed(difficulty: String, deck_size: int = 30) -> Array:
	var distribution = get_card_distribution(difficulty)
	var templates = CardProbability.get_all_card_templates()
	var deck = []
   
	var attack_templates = []
	var heal_templates = []
	var shield_templates = []
   
	for template in templates:
		match template.type:
			"attack":
				attack_templates.append(template)
			"heal":
				heal_templates.append(template)
			"shield":
				shield_templates.append(template)
   
	var min_heals = MIN_HEAL_CARDS if difficulty == "hard" else 2
	var min_shields = MIN_SHIELD_CARDS
	var min_attacks = MIN_ATTACK_CARDS
   
	var target_attacks = max(min_attacks, int(deck_size * distribution.attack_ratio))
	var target_heals = max(min_heals, int(deck_size * distribution.heal_ratio))
	var target_shields = max(min_shields, int(deck_size * distribution.shield_ratio))
   
	var total_target = target_attacks + target_heals + target_shields
	if total_target != deck_size:
		var diff = deck_size - total_target
		target_attacks += diff
   
	deck.append_array(_generate_cards_from_templates_weighted(attack_templates, target_attacks))
	deck.append_array(_generate_cards_from_templates_weighted(heal_templates, target_heals))
	deck.append_array(_generate_cards_from_templates_weighted(shield_templates, target_shields))
   
	deck.shuffle()
	return deck

static func _generate_cards_from_templates_weighted(templates: Array, count: int) -> Array:
	var cards = []
	var pool = []
   
	for template in templates:
		for i in range(template.weight):
			pool.append(template)
   
	var rarity_guaranteed = {}
	for template in templates:
		if not rarity_guaranteed.has(template.rarity):
			rarity_guaranteed[template.rarity] = template
   
	for rarity in rarity_guaranteed.keys():
		if cards.size() < count:
			var template = rarity_guaranteed[rarity]
			var card = CardData.new(
				template.name,
				template.cost,
				template.damage,
				template.heal,
				template.shield,
				template.type,
				template.description
			)
			cards.append(card)
   
	for i in range(cards.size(), count):
		if pool.size() > 0:
			var random_index = randi() % pool.size()
			var selected_template = pool[random_index]
   		
			var card = CardData.new(
				selected_template.name,
				selected_template.cost,
				selected_template.damage,
				selected_template.heal,
				selected_template.shield,
				selected_template.type,
				selected_template.description
			)
   		
			cards.append(card)
   
	return cards

static func get_balance_stats(difficulty: String) -> Dictionary:
	var player_config = get_player_config(difficulty)
	var ai_config = get_ai_config(difficulty)
	var card_dist = get_card_distribution(difficulty)
   
	var player_power = (
		player_config.hp +
		(player_config.mana * 2) +
		(player_config.cards_per_turn * 12) +
		(player_config.hand_size * 3) +
		(card_dist.heal_ratio * 20) +
		(card_dist.shield_ratio * 15)
	)
   
	var ai_power = (
		ai_config.hp +
		(ai_config.mana * 2) +
		(ai_config.cards_per_turn * 12) +
		(ai_config.hand_size * 3) +
		(ai_config.aggression * 15) +
		((1.0 - ai_config.heal_threshold) * 10)
	)
   
	return {
		"difficulty": difficulty,
		"player_power": player_power,
		"ai_power": ai_power,
		"balance_ratio": float(ai_power) / float(player_power),
		"attack_percentage": int(card_dist.attack_ratio * 100),
		"heal_percentage": int(card_dist.heal_ratio * 100),
		"shield_percentage": int(card_dist.shield_ratio * 100),
		"description": get_difficulty_description(difficulty),
		"balanced": abs(float(ai_power) / float(player_power) - 1.0) < 0.3
	}

static func get_timer_delay(timer_type: String, difficulty: String = "normal") -> float:
	var base_delay = _get_base_timer_delay(timer_type)
   
	var speed_multiplier = 1.0
	match difficulty:
		"expert":
			speed_multiplier = 0.8
		"hard":
			speed_multiplier = 0.9
		_:
			speed_multiplier = 1.0
   
	return base_delay * speed_multiplier

static func _get_base_timer_delay(timer_type: String) -> float:
	match timer_type:
		"turn_end":
			return BASE_TURN_END_DELAY
		"game_restart":
			return BASE_GAME_RESTART_DELAY
		"new_game":
			return BASE_NEW_GAME_DELAY
		"death_restart":
			return BASE_DEATH_RESTART_DELAY
		"deck_reshuffle":
			return BASE_DECK_RESHUFFLE_NOTIFICATION
		"ai_turn_start":
			return BASE_AI_TURN_START_DELAY
		"ai_card_notification":
			return BASE_AI_CARD_NOTIFICATION_DELAY
		"ai_card_play":
			return BASE_AI_CARD_PLAY_DELAY
		"ai_card_popup":
			return AI_CARD_POPUP_DURATION
		"notification_draw":
			return GAME_NOTIFICATION_DRAW_DURATION
		"notification_reshuffle":
			return GAME_NOTIFICATION_RESHUFFLE_DURATION
		"notification_bonus":
			return GAME_NOTIFICATION_BONUS_DURATION
		"notification_end":
			return GAME_NOTIFICATION_END_DURATION
		"notification_auto_turn":
			return GAME_NOTIFICATION_AUTO_TURN_DURATION
		_:
			return 1.0

static func validate_balance() -> Dictionary:
	var results = {}
	for difficulty in get_available_difficulties():
		var stats = get_balance_stats(difficulty)
		results[difficulty] = {
			"balanced": stats.balanced,
			"ratio": stats.balance_ratio,
			"warning": stats.balance_ratio > 1.4 or stats.balance_ratio < 0.7,
			"recommendation": _get_balance_recommendation(stats.balance_ratio)
		}
	return results

static func _get_balance_recommendation(ratio: float) -> String:
	if ratio > 1.3:
		return "AI too strong - consider reducing its power"
	elif ratio < 0.8:
		return "Player too strong - consider increasing challenge"
	elif ratio > 1.15:
		return "Slightly favorable to AI - good balance for high difficulty"
	elif ratio < 0.9:
		return "Slightly pro-player - consider for low difficulty"
	else:
		return "Excellent balance"
