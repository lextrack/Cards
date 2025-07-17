class_name CardDatabase
extends RefCounted

static func get_attack_cards() -> Array[Dictionary]:
	return [
		# COMMON ATTACKS
		{
			"name": "Basic Strike",
			"cost": 1,
			"damage": 1,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 100
		},
		{
			"name": "Quick Strike",
			"cost": 1,
			"damage": 2,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 80
		},
		{
			"name": "Slash",
			"cost": 2,
			"damage": 3,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 70
		},
		{
			"name": "Sword",
			"cost": 2,
			"damage": 4,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 60
		},
		
		# UNCOMMON ATTACKS
		{
			"name": "Sharp Sword",
			"cost": 3,
			"damage": 5,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 40
		},
		{
			"name": "War Axe",
			"cost": 3,
			"damage": 6,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 35
		},
		{
			"name": "Fierce Attack",
			"cost": 4,
			"damage": 7,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 30
		},
		
		# RARE ATTACKS
		{
			"name": "Deep Cut",
			"cost": 4,
			"damage": 8,
			"type": "attack",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 20
		},
		{
			"name": "Critical Strike",
			"cost": 5,
			"damage": 10,
			"type": "attack",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 15
		},
		
		# EPIC ATTACKS
		{
			"name": "Devastating Blow",
			"cost": 5,
			"damage": 12,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 8
		},
		{
			"name": "Berserker Fury",
			"cost": 6,
			"damage": 14,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 6
		},
		{
			"name": "Execution",
			"cost": 6,
			"damage": 16,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 4
		},
		{
			"name": "Annihilation",
			"cost": 7,
			"damage": 20,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 2
		}
	]

static func get_heal_cards() -> Array[Dictionary]:
	return [
		# COMMON HEALS
		{
			"name": "Bandage",
			"cost": 1,
			"heal": 2,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 50
		},
		{
			"name": "Minor Potion",
			"cost": 2,
			"heal": 3,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 40
		},
		
		# UNCOMMON HEALS
		{
			"name": "Potion",
			"cost": 2,
			"heal": 4,
			"type": "heal",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 25
		},
		{
			"name": "Healing",
			"cost": 3,
			"heal": 6,
			"type": "heal",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 20
		},
		
		# RARE HEALS
		{
			"name": "Major Healing",
			"cost": 4,
			"heal": 8,
			"type": "heal",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 12
		},
		
		# EPIC HEALS
		{
			"name": "Regeneration",
			"cost": 5,
			"heal": 12,
			"type": "heal",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 5
		}
	]

static func get_shield_cards() -> Array[Dictionary]:
	return [
		# COMMON SHIELDS
		{
			"name": "Block",
			"cost": 1,
			"shield": 2,
			"type": "shield",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 45
		},
		
		# UNCOMMON SHIELDS
		{
			"name": "Basic Shield",
			"cost": 2,
			"shield": 3,
			"type": "shield",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 25
		},
		{
			"name": "Shield",
			"cost": 2,
			"shield": 4,
			"type": "shield",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 20
		},
		
		# RARE SHIELDS
		{
			"name": "Reinforced Shield",
			"cost": 3,
			"shield": 6,
			"type": "shield",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 10
		},
		
		# EPIC SHIELDS
		{
			"name": "Fortress",
			"cost": 4,
			"shield": 8,
			"type": "shield",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 3
		}
	]

static func get_all_card_templates() -> Array[Dictionary]:
	var all_cards: Array[Dictionary] = []
	all_cards.append_array(get_attack_cards())
	all_cards.append_array(get_heal_cards())
	all_cards.append_array(get_shield_cards())
	return all_cards

static func get_cards_by_type(card_type: String) -> Array[Dictionary]:
	match card_type.to_lower():
		"attack":
			return get_attack_cards()
		"heal":
			return get_heal_cards()
		"shield":
			return get_shield_cards()
		_:
			push_error("Tipo de carta desconocido: " + card_type)
			return []

static func get_cards_by_rarity(rarity: RaritySystem.Rarity) -> Array[Dictionary]:
	var filtered_cards: Array[Dictionary] = []
	var all_cards = get_all_card_templates()
	
	for card in all_cards:
		if card.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			filtered_cards.append(card)
	
	return filtered_cards

static func get_cards_by_type_and_rarity(card_type: String, rarity: RaritySystem.Rarity) -> Array[Dictionary]:
	var type_cards = get_cards_by_type(card_type)
	var filtered_cards: Array[Dictionary] = []
	
	for card in type_cards:
		if card.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			filtered_cards.append(card)
	
	return filtered_cards

static func find_card_by_name(name: String) -> Dictionary:
	var all_cards = get_all_card_templates()
	
	for card in all_cards:
		if card.get("name", "") == name:
			return card
	
	push_warning("Card not found: " + name)
	return {}

static func get_card_count() -> Dictionary:
	return {
		"attack": get_attack_cards().size(),
		"heal": get_heal_cards().size(),
		"shield": get_shield_cards().size(),
		"total": get_all_card_templates().size()
	}

static func validate_database() -> Dictionary:
	var all_cards = get_all_card_templates()
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"total_cards": all_cards.size()
	}
	
	var card_names = []
	
	for card in all_cards:
		if not card.has("name") or card.get("name", "") == "":
			validation.errors.append("Nameless card found")
			validation.valid = false
		
		if not card.has("type") or card.get("type", "") == "":
			validation.errors.append("Card without type: " + str(card.get("name", "No name")))
			validation.valid = false
		
		if not card.has("cost") or card.get("cost", 0) <= 0:
			validation.errors.append("Invalid cost for: " + str(card.get("name", "No name")))
			validation.valid = false
		
		var name = card.get("name", "")
		if name in card_names:
			validation.errors.append("Duplicate name: " + name)
			validation.valid = false
		else:
			card_names.append(name)
		
		var power = card.get("damage", 0) + card.get("heal", 0) + card.get("shield", 0)
		if power == 0:
			validation.warnings.append("Card with no effect: " + name)
		elif power > 25:
			validation.warnings.append("Card possibly too powerful: " + name + " (power: " + str(power) + ")")
	
	return validation
