class_name DeckConfig
extends Resource

@export var deck_size: int = 30
@export var attack_ratio: float = 0.7
@export var heal_ratio: float = 0.2
@export var shield_ratio: float = 0.1
@export var difficulty: String = "normal"
@export var guaranteed_rarities: bool = true
@export var min_heal_cards: int = 2
@export var min_shield_cards: int = 2
@export var min_attack_cards: int = 15

func _init(
	size: int = 30,
	attack: float = 0.7,
	heal: float = 0.2,
	shield: float = 0.1,
	diff: String = "normal"
):
	deck_size = size
	attack_ratio = attack
	heal_ratio = heal
	shield_ratio = shield
	difficulty = diff

func get_target_attack_cards() -> int:
	return max(min_attack_cards, int(deck_size * attack_ratio))

func get_target_heal_cards() -> int:
	return max(min_heal_cards, int(deck_size * heal_ratio))

func get_target_shield_cards() -> int:
	return max(min_shield_cards, int(deck_size * shield_ratio))

func validate() -> bool:
	var total_ratio = attack_ratio + heal_ratio + shield_ratio
	return abs(total_ratio - 1.0) < 0.01

func normalize_ratios():
	var total = attack_ratio + heal_ratio + shield_ratio
	if total > 0:
		attack_ratio /= total
		heal_ratio /= total
		shield_ratio /= total

static func create_for_difficulty(difficulty: String) -> DeckConfig:
	var distribution = GameBalance.get_card_distribution(difficulty)
	var player_config = GameBalance.get_player_config(difficulty)
	
	return DeckConfig.new(
		player_config.deck_size,
		distribution.attack_ratio,
		distribution.heal_ratio,
		distribution.shield_ratio,
		difficulty
	)

func get_description() -> String:
	return "Tamaño: %d | Ataque: %d%% | Curación: %d%% | Escudo: %d%%" % [
		deck_size,
		int(attack_ratio * 100),
		int(heal_ratio * 100),
		int(shield_ratio * 100)
	]
