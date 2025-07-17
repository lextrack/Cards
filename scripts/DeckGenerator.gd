class_name DeckGenerator
extends RefCounted

static func create_deck(config: DeckConfig) -> Array:
	if not config.validate():
		push_warning("Invalid deck configuration, normalizing...")
		config.normalize_ratios()
	
	var pool = _create_balanced_pool(config)
	return pool.generate_deck(config.deck_size, config)

static func create_themed_deck(theme: String, deck_size: int = 30) -> Array:
	var config = _get_theme_config(theme, deck_size)
	return create_deck(config)

static func create_difficulty_deck(difficulty: String, deck_size: int = 30) -> Array:
	var config = DeckConfig.create_for_difficulty(difficulty)
	config.deck_size = deck_size
	return create_deck(config)

static func create_random_deck(deck_size: int = 30) -> Array:
	var pool = WeightedCardPool.new()
	pool.add_templates(CardDatabase.get_all_card_templates())
	return pool.generate_deck(deck_size)

static func create_custom_deck(templates: Array) -> Array:
	var cards: Array = []
	
	for template in templates:
		var card = CardBuilder.from_template(template)
		if card:
			cards.append(card)
	
	cards.shuffle()
	return cards

static func create_balanced_deck(
	deck_size: int = 30,
	attack_ratio: float = 0.7,
	heal_ratio: float = 0.2,
	shield_ratio: float = 0.1
) -> Array:
	var config = DeckConfig.new(deck_size, attack_ratio, heal_ratio, shield_ratio)
	return create_deck(config)

static func create_starter_deck() -> Array:
	# Basic deck for new players
	var templates = [
		# Basic attacks (15 cards)
		CardDatabase.find_card_by_name("Basic Strike"),
		CardDatabase.find_card_by_name("Basic Strike"),
		CardDatabase.find_card_by_name("Basic Strike"),
		CardDatabase.find_card_by_name("Quick Strike"),
		CardDatabase.find_card_by_name("Quick Strike"),
		CardDatabase.find_card_by_name("Slash"),
		CardDatabase.find_card_by_name("Slash"),
		CardDatabase.find_card_by_name("Sword"),
		CardDatabase.find_card_by_name("Sword"),
		CardDatabase.find_card_by_name("Sharp Sword"),
		CardDatabase.find_card_by_name("War Axe"),
		CardDatabase.find_card_by_name("Fierce Attack"),
		CardDatabase.find_card_by_name("Deep Cut"),
		CardDatabase.find_card_by_name("Critical Strike"),
		CardDatabase.find_card_by_name("Devastating Blow"),
		
		# Healing (8 cards)
		CardDatabase.find_card_by_name("Bandage"),
		CardDatabase.find_card_by_name("Bandage"),
		CardDatabase.find_card_by_name("Minor Potion"),
		CardDatabase.find_card_by_name("Minor Potion"),
		CardDatabase.find_card_by_name("Potion"),
		CardDatabase.find_card_by_name("Healing"),
		CardDatabase.find_card_by_name("Major Healing"),
		CardDatabase.find_card_by_name("Regeneration"),
		
		# Defense (7 cards)
		CardDatabase.find_card_by_name("Block"),
		CardDatabase.find_card_by_name("Block"),
		CardDatabase.find_card_by_name("Basic Shield"),
		CardDatabase.find_card_by_name("Shield"),
		CardDatabase.find_card_by_name("Shield"),
		CardDatabase.find_card_by_name("Reinforced Shield"),
		CardDatabase.find_card_by_name("Fortress")
	]
	
	return create_custom_deck(templates.filter(func(t): return not t.is_empty()))

static func create_arena_deck() -> Array:
	var config = DeckConfig.new()
	config.guaranteed_rarities = true
	config.deck_size = 30
	config.attack_ratio = 0.65
	config.heal_ratio = 0.25
	config.shield_ratio = 0.10
	
	return create_deck(config)

static func create_aggro_deck(deck_size: int = 30) -> Array:
	return create_themed_deck("aggressive", deck_size)

static func create_control_deck(deck_size: int = 30) -> Array:
	return create_themed_deck("defensive", deck_size)

static func create_midrange_deck(deck_size: int = 30) -> Array:
	return create_themed_deck("balanced", deck_size)

static func _create_balanced_pool(config: DeckConfig) -> WeightedCardPool:
	var pool = WeightedCardPool.new()
	
	var target_attacks = config.get_target_attack_cards()
	var target_heals = config.get_target_heal_cards()
	var target_shields = config.get_target_shield_cards()
	
	pool.add_cards_by_type("attack", target_attacks)
	pool.add_cards_by_type("heal", target_heals)
	pool.add_cards_by_type("shield", target_shields)
	
	return pool

static func _get_theme_config(theme: String, deck_size: int) -> DeckConfig:
	match theme.to_lower():
		"aggressive", "aggro":
			return DeckConfig.new(deck_size, 0.85, 0.10, 0.05, "aggro")
		"defensive", "control":
			return DeckConfig.new(deck_size, 0.40, 0.35, 0.25, "control")
		"balanced", "midrange":
			return DeckConfig.new(deck_size, 0.65, 0.20, 0.15, "midrange")
		"combo":
			return DeckConfig.new(deck_size, 0.50, 0.30, 0.20, "combo")
		"rush":
			return DeckConfig.new(deck_size, 0.90, 0.05, 0.05, "rush")
		"tank":
			return DeckConfig.new(deck_size, 0.30, 0.30, 0.40, "tank")
		_:
			push_warning("Unknown theme: " + theme + ", using balanced configuration")
			return DeckConfig.new(deck_size, 0.70, 0.20, 0.10, "balanced")

static func analyze_deck(deck: Array) -> Dictionary:
	var analysis = {
		"total_cards": deck.size(),
		"average_cost": 0.0,
		"total_damage": 0,
		"total_heal": 0,
		"total_shield": 0,
		"rarity_distribution": {},
		"type_distribution": {},
		"cost_distribution": {},
		"power_level": 0,
		"balance_score": 0.0
	}
	
	for rarity in RaritySystem.get_all_rarities():
		analysis.rarity_distribution[RaritySystem.get_rarity_string(rarity)] = 0
	
	analysis.type_distribution = {"attack": 0, "heal": 0, "shield": 0}
	
	var total_cost = 0
	var total_power = 0
	
	for card in deck:
		if not card is CardData:
			continue
		
		total_cost += card.cost
		if not analysis.cost_distribution.has(card.cost):
			analysis.cost_distribution[card.cost] = 0
		analysis.cost_distribution[card.cost] += 1
		
		analysis.total_damage += card.damage
		analysis.total_heal += card.heal
		analysis.total_shield += card.shield
		
		var card_power = card.damage + card.heal + card.shield
		total_power += card_power
		
		if analysis.type_distribution.has(card.card_type):
			analysis.type_distribution[card.card_type] += 1
		
		var rarity = RaritySystem.calculate_card_rarity(card.damage, card.heal, card.shield)
		var rarity_str = RaritySystem.get_rarity_string(rarity)
		analysis.rarity_distribution[rarity_str] += 1
	
	if deck.size() > 0:
		analysis.average_cost = float(total_cost) / deck.size()
		analysis.power_level = total_power
		analysis.balance_score = _calculate_balance_score(analysis)
	
	return analysis

static func _calculate_balance_score(analysis: Dictionary) -> float:
	var score = 5.0
	
	var total_cards = analysis.total_cards
	if total_cards > 0:
		var attack_ratio = float(analysis.type_distribution.get("attack", 0)) / total_cards
		var heal_ratio = float(analysis.type_distribution.get("heal", 0)) / total_cards
		var shield_ratio = float(analysis.type_distribution.get("shield", 0)) / total_cards
		
		if heal_ratio < 0.1:
			score -= 1.0
		if shield_ratio < 0.05:
			score -= 0.5
		
		if attack_ratio > 0.9:
			score -= 0.5
		if attack_ratio < 0.4:
			score -= 0.5
	
	var epic_count = analysis.rarity_distribution.get("epic", 0)
	var rare_count = analysis.rarity_distribution.get("rare", 0)
	
	if epic_count >= 1 and epic_count <= 3:
		score += 0.5
	if rare_count >= 3 and rare_count <= 8:
		score += 0.5
	
	return clamp(score, 0.0, 10.0)

static func suggest_deck_improvements(deck: Array) -> Array:
	var suggestions: Array = []
	var analysis = analyze_deck(deck)
	
	var total_cards = analysis.total_cards
	if total_cards == 0:
		suggestions.append("Deck is empty")
		return suggestions
	
	var attack_ratio = float(analysis.type_distribution.get("attack", 0)) / total_cards
	var heal_ratio = float(analysis.type_distribution.get("heal", 0)) / total_cards
	var shield_ratio = float(analysis.type_distribution.get("shield", 0)) / total_cards
	
	if heal_ratio < 0.1:
		suggestions.append("Consider adding more healing cards")
	
	if shield_ratio < 0.05:
		suggestions.append("Add some defense cards to survive")
	
	if attack_ratio > 0.9:
		suggestions.append("Deck is too aggressive, consider adding support cards")
	
	if analysis.average_cost > 4.0:
		suggestions.append("Average cost is high, add cheaper cards")
	
	if analysis.average_cost < 2.0:
		suggestions.append("Deck is too cheap, consider more powerful cards")
	
	var epic_count = analysis.rarity_distribution.get("epic", 0)
	if epic_count == 0:
		suggestions.append("Adding at least one epic card will improve the deck")
	
	if epic_count > 5:
		suggestions.append("Too many epic cards can make the deck inconsistent")
	
	return suggestions

static func optimize_deck_for_difficulty(deck: Array, difficulty: String) -> Array:
	var config = DeckConfig.create_for_difficulty(difficulty)
	
	return create_deck(config)
