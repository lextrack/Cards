class_name CardProbability
extends RefCounted

class CardTemplate:
	var name: String
	var cost: int
	var damage: int
	var heal: int
	var shield: int
	var type: String
	var description: String
	var rarity: String
	var weight: int
	
	func _init(n: String, c: int, dmg: int, h: int, s: int, t: String, desc: String, r: String, w: int):
		name = n
		cost = c
		damage = dmg
		heal = h
		shield = s
		type = t
		description = desc
		rarity = r
		weight = w

static func get_all_card_templates() -> Array:
	var templates = []
	
	# ATAQUES COMUNES (peso alto = hay más de ellas en cada partida)
	templates.append(CardTemplate.new("Golpe Básico", 1, 1, 0, 0, "attack", "Daño: 1", "common", 100))
	templates.append(CardTemplate.new("Golpe Rápido", 1, 2, 0, 0, "attack", "Daño: 2", "common", 80))
	templates.append(CardTemplate.new("Cuchillada", 2, 3, 0, 0, "attack", "Daño: 3", "common", 70))
	templates.append(CardTemplate.new("Espada", 2, 4, 0, 0, "attack", "Daño: 4", "common", 60))
	
	# ATAQUES POCO COMUNES
	templates.append(CardTemplate.new("Espada Afilada", 3, 5, 0, 0, "attack", "Daño: 5", "uncommon", 40))
	templates.append(CardTemplate.new("Hacha de Guerra", 3, 6, 0, 0, "attack", "Daño: 6", "uncommon", 35))
	templates.append(CardTemplate.new("Ataque Feroz", 4, 7, 0, 0, "attack", "Daño: 7", "uncommon", 30))
	
	# ATAQUES RAROS
	templates.append(CardTemplate.new("Corte Profundo", 4, 8, 0, 0, "attack", "Daño: 8", "rare", 20))
	templates.append(CardTemplate.new("Golpe Crítico", 5, 10, 0, 0, "attack", "Daño: 10", "rare", 15))
	
	# FINISHERS ÉPICOS
	templates.append(CardTemplate.new("Golpe Devastador", 5, 12, 0, 0, "attack", "Daño: 12", "epic", 8))
	templates.append(CardTemplate.new("Furia Berserker", 6, 14, 0, 0, "attack", "Daño: 14", "epic", 6))
	templates.append(CardTemplate.new("Ejecución", 6, 16, 0, 0, "attack", "Daño: 16", "epic", 4))
	templates.append(CardTemplate.new("Aniquilación", 7, 20, 0, 0, "attack", "Daño: 20", "epic", 2))
	
	# CURACIONES
	templates.append(CardTemplate.new("Vendaje", 1, 0, 2, 0, "heal", "Cura: 2", "common", 50))
	templates.append(CardTemplate.new("Poción Menor", 2, 0, 3, 0, "heal", "Cura: 3", "common", 40))
	templates.append(CardTemplate.new("Poción", 2, 0, 4, 0, "heal", "Cura: 4", "uncommon", 25))
	templates.append(CardTemplate.new("Curación", 3, 0, 6, 0, "heal", "Cura: 6", "uncommon", 20))
	templates.append(CardTemplate.new("Curación Mayor", 4, 0, 8, 0, "heal", "Cura: 8", "rare", 12))
	templates.append(CardTemplate.new("Regeneración", 5, 0, 12, 0, "heal", "Cura: 12", "epic", 5))
	
	# DEFENSAS
	templates.append(CardTemplate.new("Bloqueo", 1, 0, 0, 2, "shield", "Escudo: 2", "common", 45))
	templates.append(CardTemplate.new("Escudo Básico", 2, 0, 0, 3, "shield", "Escudo: 3", "uncommon", 25))
	templates.append(CardTemplate.new("Escudo", 2, 0, 0, 4, "shield", "Escudo: 4", "uncommon", 20))
	templates.append(CardTemplate.new("Escudo Reforzado", 3, 0, 0, 6, "shield", "Escudo: 6", "rare", 10))
	templates.append(CardTemplate.new("Fortaleza", 4, 0, 0, 8, "shield", "Escudo: 8", "epic", 3))
	
	return templates

static func create_weighted_deck(deck_size: int = 30) -> Array:
	var templates = get_all_card_templates()
	var deck = []
	
	var card_pool = []
	for template in templates:
		for i in range(template.weight):
			card_pool.append(template)

	for i in range(deck_size):
		if card_pool.size() > 0:
			var random_index = randi() % card_pool.size()
			var selected_template = card_pool[random_index]
			
			var card = CardData.new(
				selected_template.name,
				selected_template.cost,
				selected_template.damage,
				selected_template.heal,
				selected_template.shield,
				selected_template.type,
				selected_template.description
			)
			
			deck.append(card)
	
	deck.shuffle()
	return deck

static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color.WHITE
		"uncommon": 
			return Color.GREEN
		"rare":
			return Color.BLUE
		"epic":
			return Color.PURPLE
		_:
			return Color.GRAY

static func calculate_card_rarity(damage: int, heal: int, shield: int) -> String:
	var power = damage + heal + shield
	
	if power >= 15:
		return "epic"
	elif power >= 8:
		return "rare"
	elif power >= 5:
		return "uncommon"
	else:
		return "common"

static func get_deck_stats(deck: Array) -> Dictionary:
	var stats = {
		"total_cards": deck.size(),
		"common": 0,
		"uncommon": 0,
		"rare": 0,
		"epic": 0,
		"attack_cards": 0,
		"heal_cards": 0,
		"shield_cards": 0
	}
	
	for card in deck:
		if card is CardData:
			var rarity = calculate_card_rarity(card.damage, card.heal, card.shield)
			stats[rarity] += 1
			
			match card.card_type:
				"attack":
					stats["attack_cards"] += 1
				"heal":
					stats["heal_cards"] += 1
				"shield":
					stats["shield_cards"] += 1
	
	return stats

static func create_balanced_deck(deck_size: int = 30, attack_ratio: float = 0.8, heal_ratio: float = 0.12, shield_ratio: float = 0.08) -> Array:
	var templates = get_all_card_templates()
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
	
	var attack_count = int(deck_size * attack_ratio)
	var heal_count = int(deck_size * heal_ratio)
	var shield_count = int(deck_size * shield_ratio)
	
	var remaining = deck_size - (attack_count + heal_count + shield_count)
	attack_count += remaining
	
	deck.append_array(_generate_cards_from_templates(attack_templates, attack_count))
	deck.append_array(_generate_cards_from_templates(heal_templates, heal_count))
	deck.append_array(_generate_cards_from_templates(shield_templates, shield_count))
	deck.shuffle()
	return deck

static func _generate_cards_from_templates(templates: Array, count: int) -> Array:
	var cards = []
	var pool = []
	
	for template in templates:
		for i in range(template.weight):
			pool.append(template)
	
	for i in range(count):
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
