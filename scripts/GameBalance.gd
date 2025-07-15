class_name GameBalance
extends RefCounted

const DEFAULT_MANA: int = 10
const DEFAULT_HAND_SIZE: int = 5
const DEFAULT_DECK_SIZE: int = 30

const DAMAGE_BONUS_TURN_1: int = 4
const DAMAGE_BONUS_TURN_2: int = 7
const DAMAGE_BONUS_TURN_3: int = 10
const DAMAGE_BONUS_TURN_4: int = 15
const DAMAGE_BONUS_1: int = 1
const DAMAGE_BONUS_2: int = 2
const DAMAGE_BONUS_3: int = 3
const DAMAGE_BONUS_4: int = 4

const TURN_END_DELAY: float = 0.5
const GAME_RESTART_DELAY: float = 0.8
const NEW_GAME_DELAY: float = 0.5
const DEATH_RESTART_DELAY: float = 1.0
const DECK_RESHUFFLE_NOTIFICATION: float = 1.2
const AI_TURN_START_DELAY: float = 1.2
const AI_CARD_NOTIFICATION_DELAY: float = 1.2
const AI_CARD_PLAY_DELAY: float = 0.8

const AI_CARD_POPUP_DURATION: float = 1.2
const GAME_NOTIFICATION_DRAW_DURATION: float = 1.5
const GAME_NOTIFICATION_RESHUFFLE_DURATION: float = 1.8
const GAME_NOTIFICATION_BONUS_DURATION: float = 2.5
const GAME_NOTIFICATION_END_DURATION: float = 2.5
const GAME_NOTIFICATION_AUTO_TURN_DURATION: float = 1.5

enum Difficulty {
	NORMAL,
	HARD,
	EXPERT
}

static func get_player_config(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"hp": 35,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE
			}
		"hard":
			return {
				"hp": 33,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 1,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE
			}
		"expert":
			return {
				"hp": 30,
				"mana": 8,
				"cards_per_turn": 1,
				"hand_size": 4,
				"deck_size": 25
			}
		_:
			return get_player_config("normal")

static func get_ai_config(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"hp": 35,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.5,
				"heal_threshold": 0.4
			}
		"hard":
			return {
				"hp": 38,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.7,
				"heal_threshold": 0.3
			}
		"expert":
			return {
				"hp": 40,
				"mana": 12,
				"cards_per_turn": 3,
				"hand_size": 6,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.8,
				"heal_threshold": 0.25
			}
		_:
			return get_ai_config("normal")

static func get_card_distribution(difficulty: String) -> Dictionary:
	# Player use this
	match difficulty:
		"normal":
			return {
				"attack_ratio": 0.8,
				"heal_ratio": 0.10,
				"shield_ratio": 0.08
			}
		"hard":
			return {
				"attack_ratio": 0.85,
				"heal_ratio": 0.12,
				"shield_ratio": 0.15
			}
		"expert":
			return {
				"attack_ratio": 0.78,
				"heal_ratio": 0.08,
				"shield_ratio": 0.25
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
			return "Sin bonus"
		1:
			return "Daño aumento en +1"
		2:
			return "Daño aumento en +2"
		3:
			return "Daño aumento en +3"
		4:
			return "Daño aumento en +4"
		_:
			return "Bonus: +" + str(bonus) + " daño"

static func get_available_difficulties() -> Array:
	return ["normal", "hard", "expert"]

static func get_difficulty_description(difficulty: String) -> String:
	match difficulty:
		"normal":
			return "Equilibrado - Lo más simple"
		"hard":
			return "Desafiante - IA más fuerte, tú juegas 1 carta"
		"expert":
			return "Experto - Recursos limitados, IA poderosa"
		_:
			return "Dificultad desconocida"

static func setup_player(player: Player, difficulty: String, is_ai: bool = false):
	var config = get_ai_config(difficulty) if is_ai else get_player_config(difficulty)
	
	player.max_hp = config.hp
	player.current_hp = config.hp
	player.max_mana = config.mana
	player.current_mana = config.mana
	player.max_hand_size = config.hand_size
	player.difficulty = difficulty
	
	if is_ai and config.has("aggression"):
		pass

static func get_balance_stats(difficulty: String) -> Dictionary:
	var player_config = get_player_config(difficulty)
	var ai_config = get_ai_config(difficulty)
	var card_dist = get_card_distribution(difficulty)
	
	var player_power = player_config.hp + (player_config.mana * 2) + (player_config.cards_per_turn * 10)
	var ai_power = ai_config.hp + (ai_config.mana * 2) + (ai_config.cards_per_turn * 10)
	
	return {
		"difficulty": difficulty,
		"player_power": player_power,
		"ai_power": ai_power,
		"balance_ratio": float(ai_power) / float(player_power),
		"attack_percentage": int(card_dist.attack_ratio * 100),
		"description": get_difficulty_description(difficulty)
	}

static func get_timer_delay(timer_type: String) -> float:
	match timer_type:
		"turn_end":
			return TURN_END_DELAY
		"game_restart":
			return GAME_RESTART_DELAY
		"new_game":
			return NEW_GAME_DELAY
		"death_restart":
			return DEATH_RESTART_DELAY
		"deck_reshuffle":
			return DECK_RESHUFFLE_NOTIFICATION
		"ai_turn_start":
			return AI_TURN_START_DELAY
		"ai_card_notification":
			return AI_CARD_NOTIFICATION_DELAY
		"ai_card_play":
			return AI_CARD_PLAY_DELAY
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
