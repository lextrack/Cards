class_name GameBalance
extends RefCounted
# =============================================================================
# CONFIGURACIÓN GENERAL
# =============================================================================

# Configuraciones básicas del juego
const DEFAULT_MANA: int = 10
const DEFAULT_HAND_SIZE: int = 5
const DEFAULT_DECK_SIZE: int = 30

# Turnos para bonus de daño
const DAMAGE_BONUS_TURN_1: int = 6   # Turno donde se activa +1 daño
const DAMAGE_BONUS_TURN_2: int = 12  # Turno donde se activa +2 daño
const DAMAGE_BONUS_1: int = 1        # Primer bonus de daño
const DAMAGE_BONUS_2: int = 2        # Segundo bonus de daño

# =============================================================================
# TIEMPOS DE ESPERA Y DURACIONES
# =============================================================================

# Tiempos de espera en segundos
const TURN_END_DELAY: float = 0.5
const GAME_RESTART_DELAY: float = 0.8
const NEW_GAME_DELAY: float = 0.5
const DEATH_RESTART_DELAY: float = 1.0
const DECK_RESHUFFLE_NOTIFICATION: float = 1.0
const AI_TURN_START_DELAY: float = 1.2
const AI_CARD_NOTIFICATION_DELAY: float = 1.3
const AI_CARD_PLAY_DELAY: float = 0.8

# Duraciones de notificaciones
const AI_CARD_POPUP_DURATION: float = 1.0
const GAME_NOTIFICATION_DRAW_DURATION: float = 1.2
const GAME_NOTIFICATION_RESHUFFLE_DURATION: float = 1.8
const GAME_NOTIFICATION_BONUS_DURATION: float = 2.0
const GAME_NOTIFICATION_END_DURATION: float = 2.5
const GAME_NOTIFICATION_AUTO_TURN_DURATION: float = 1.0

# =============================================================================
# CONFIGURACIÓN POR DIFICULTAD
# =============================================================================

enum Difficulty {
	NORMAL,
	HARD,
	EXPERT,    # Para futuras expansiones
	NIGHTMARE  # Para futuras expansiones
}

# Configuración del jugador por dificultad
static func get_player_config(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"hp": 20,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE
			}
		"hard":
			return {
				"hp": 20,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 1,  # Solo 1 carta por turno
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE
			}
		"expert":
			return {
				"hp": 15,  # Menos vida
				"mana": 8,  # Menos maná
				"cards_per_turn": 1,
				"hand_size": 4,  # Menos cartas en mano
				"deck_size": 25
			}
		"nightmare":
			return {
				"hp": 10,
				"mana": 6,
				"cards_per_turn": 1,
				"hand_size": 3,
				"deck_size": 20
			}
		_:
			return get_player_config("normal")

# Configuración de la IA por dificultad
static func get_ai_config(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"hp": 20,
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.5,  # 50% agresivo
				"heal_threshold": 0.4  # Se cura cuando HP < 40%
			}
		"hard":
			return {
				"hp": 25,  # Más vida para la IA
				"mana": DEFAULT_MANA,
				"cards_per_turn": 2,  # IA mantiene 2 cartas
				"hand_size": DEFAULT_HAND_SIZE,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.7,  # Más agresiva
				"heal_threshold": 0.3  # Se cura menos frecuentemente
			}
		"expert":
			return {
				"hp": 30,
				"mana": 12,  # Más maná
				"cards_per_turn": 3,  # Más cartas por turno
				"hand_size": 6,
				"deck_size": DEFAULT_DECK_SIZE,
				"aggression": 0.8,
				"heal_threshold": 0.25
			}
		"nightmare":
			return {
				"hp": 40,
				"mana": 15,
				"cards_per_turn": 4,
				"hand_size": 7,
				"deck_size": 35,
				"aggression": 0.9,
				"heal_threshold": 0.2
			}
		_:
			return get_ai_config("normal")

# =============================================================================
# CONFIGURACIÓN DE CARTAS
# =============================================================================

# Distribución de tipos de cartas por dificultad
static func get_card_distribution(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return {
				"attack_ratio": 0.8,    # 80% ataques
				"heal_ratio": 0.12,     # 12% curación
				"shield_ratio": 0.08    # 8% escudos
			}
		"hard":
			return {
				"attack_ratio": 0.85,   # Más ataques
				"heal_ratio": 0.10,     # Menos curación
				"shield_ratio": 0.05    # Menos escudos
			}
		"expert":
			return {
				"attack_ratio": 0.9,    # Casi todo ataques
				"heal_ratio": 0.07,
				"shield_ratio": 0.03
			}
		"nightmare":
			return {
				"attack_ratio": 0.95,   # Solo ataques
				"heal_ratio": 0.03,
				"shield_ratio": 0.02
			}
		_:
			return get_card_distribution("normal")

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

# Obtener bonus de daño según el turno
static func get_damage_bonus(turn_number: int) -> int:
	if turn_number >= DAMAGE_BONUS_TURN_2:
		return DAMAGE_BONUS_2
	elif turn_number >= DAMAGE_BONUS_TURN_1:
		return DAMAGE_BONUS_1
	else:
		return 0

# Verificar si es tiempo de bonus de daño
static func is_damage_bonus_turn(turn_number: int) -> bool:
	return turn_number == DAMAGE_BONUS_TURN_1 or turn_number == DAMAGE_BONUS_TURN_2

# Obtener todas las dificultades disponibles
static func get_available_difficulties() -> Array:
	return ["normal", "hard", "expert", "nightmare"]

# Obtener descripción de dificultad
static func get_difficulty_description(difficulty: String) -> String:
	match difficulty:
		"normal":
			return "Equilibrado - Aprende las mecánicas"
		"hard":
			return "Desafiante - IA más fuerte, tú juegas 1 carta"
		"expert":
			return "Experto - Recursos limitados, IA poderosa"
		"nightmare":
			return "Pesadilla - Solo para maestros"
		_:
			return "Dificultad desconocida"

# Obtener configuración completa para un jugador
static func setup_player(player: Player, difficulty: String, is_ai: bool = false):
	var config = get_ai_config(difficulty) if is_ai else get_player_config(difficulty)
	
	player.max_hp = config.hp
	player.current_hp = config.hp
	player.max_mana = config.mana
	player.current_mana = config.mana
	player.max_hand_size = config.hand_size
	player.difficulty = difficulty
	
	# Configuración específica de IA
	if is_ai and config.has("aggression"):
		# Aquí puedes añadir propiedades específicas de IA si las necesitas
		pass

# Calcular estadísticas de balance
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

# =============================================================================
# CONFIGURACIÓN DE TIMERS Y UI
# =============================================================================

# Obtener tiempo de espera específico
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
		# Duraciones de notificaciones
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

# =============================================================================
# FUNCIONES DE DEBUG
# =============================================================================

# Imprimir configuración actual
static func print_current_config(difficulty: String):
	print("\n========== CONFIGURACIÓN DE JUEGO ==========")
	print("Dificultad: " + difficulty.to_upper())
	print("Descripción: " + get_difficulty_description(difficulty))
	
	var player_config = get_player_config(difficulty)
	var ai_config = get_ai_config(difficulty)
	var card_dist = get_card_distribution(difficulty)
	
	print("\n--- JUGADOR ---")
	print("HP: " + str(player_config.hp))
	print("Maná: " + str(player_config.mana))
	print("Cartas por turno: " + str(player_config.cards_per_turn))
	
	print("\n--- IA ---")
	print("HP: " + str(ai_config.hp))
	print("Maná: " + str(ai_config.mana))
	print("Cartas por turno: " + str(ai_config.cards_per_turn))
	
	print("\n--- DISTRIBUCIÓN DE CARTAS ---")
	print("Ataques: " + str(int(card_dist.attack_ratio * 100)) + "%")
	print("Curación: " + str(int(card_dist.heal_ratio * 100)) + "%")
	print("Escudos: " + str(int(card_dist.shield_ratio * 100)) + "%")
	
	print("\n--- TIEMPOS DE NOTIFICACIÓN ---")
	print("Popup IA: " + str(AI_CARD_POPUP_DURATION) + "s")
	print("Robo cartas: " + str(GAME_NOTIFICATION_DRAW_DURATION) + "s")
	print("Remezcla: " + str(GAME_NOTIFICATION_RESHUFFLE_DURATION) + "s")
	print("Bonus daño: " + str(GAME_NOTIFICATION_BONUS_DURATION) + "s")
	print("==========================================\n")
