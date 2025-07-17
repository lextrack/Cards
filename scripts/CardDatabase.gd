class_name CardDatabase
extends RefCounted

# Definiciones de cartas organizadas por tipo y rareza
static func get_attack_cards() -> Array[Dictionary]:
	return [
		# ATAQUES COMUNES
		{
			"name": "Golpe Básico",
			"cost": 1,
			"damage": 1,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 100
		},
		{
			"name": "Golpe Rápido",
			"cost": 1,
			"damage": 2,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 80
		},
		{
			"name": "Cuchillada",
			"cost": 2,
			"damage": 3,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 70
		},
		{
			"name": "Espada",
			"cost": 2,
			"damage": 4,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 60
		},
		
		# ATAQUES POCO COMUNES
		{
			"name": "Espada Afilada",
			"cost": 3,
			"damage": 5,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 40
		},
		{
			"name": "Hacha de Guerra",
			"cost": 3,
			"damage": 6,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 35
		},
		{
			"name": "Ataque Feroz",
			"cost": 4,
			"damage": 7,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 30
		},
		
		# ATAQUES RAROS
		{
			"name": "Corte Profundo",
			"cost": 4,
			"damage": 8,
			"type": "attack",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 20
		},
		{
			"name": "Golpe Crítico",
			"cost": 5,
			"damage": 10,
			"type": "attack",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 15
		},
		
		# ATAQUES ÉPICOS
		{
			"name": "Golpe Devastador",
			"cost": 5,
			"damage": 12,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 8
		},
		{
			"name": "Furia Berserker",
			"cost": 6,
			"damage": 14,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 6
		},
		{
			"name": "Ejecución",
			"cost": 6,
			"damage": 16,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 4
		},
		{
			"name": "Aniquilación",
			"cost": 7,
			"damage": 20,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 2
		}
	]

static func get_heal_cards() -> Array[Dictionary]:
	return [
		# CURACIONES COMUNES
		{
			"name": "Vendaje",
			"cost": 1,
			"heal": 2,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 50
		},
		{
			"name": "Poción Menor",
			"cost": 2,
			"heal": 3,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 40
		},
		
		# CURACIONES POCO COMUNES
		{
			"name": "Poción",
			"cost": 2,
			"heal": 4,
			"type": "heal",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 25
		},
		{
			"name": "Curación",
			"cost": 3,
			"heal": 6,
			"type": "heal",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 20
		},
		
		# CURACIONES RARAS
		{
			"name": "Curación Mayor",
			"cost": 4,
			"heal": 8,
			"type": "heal",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 12
		},
		
		# CURACIONES ÉPICAS
		{
			"name": "Regeneración",
			"cost": 5,
			"heal": 12,
			"type": "heal",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 5
		}
	]

static func get_shield_cards() -> Array[Dictionary]:
	return [
		# DEFENSAS COMUNES
		{
			"name": "Bloqueo",
			"cost": 1,
			"shield": 2,
			"type": "shield",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 45
		},
		
		# DEFENSAS POCO COMUNES
		{
			"name": "Escudo Básico",
			"cost": 2,
			"shield": 3,
			"type": "shield",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 25
		},
		{
			"name": "Escudo",
			"cost": 2,
			"shield": 4,
			"type": "shield",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 20
		},
		
		# DEFENSAS RARAS
		{
			"name": "Escudo Reforzado",
			"cost": 3,
			"shield": 6,
			"type": "shield",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 10
		},
		
		# DEFENSAS ÉPICAS
		{
			"name": "Fortaleza",
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
	
	push_warning("Carta no encontrada: " + name)
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
		# Verificar campos requeridos
		if not card.has("name") or card.get("name", "") == "":
			validation.errors.append("Carta sin nombre encontrada")
			validation.valid = false
		
		if not card.has("type") or card.get("type", "") == "":
			validation.errors.append("Carta sin tipo: " + str(card.get("name", "Sin nombre")))
			validation.valid = false
		
		if not card.has("cost") or card.get("cost", 0) <= 0:
			validation.errors.append("Costo inválido para: " + str(card.get("name", "Sin nombre")))
			validation.valid = false
		
		# Verificar nombres duplicados
		var name = card.get("name", "")
		if name in card_names:
			validation.errors.append("Nombre duplicado: " + name)
			validation.valid = false
		else:
			card_names.append(name)
		
		# Verificar balance de poder
		var power = card.get("damage", 0) + card.get("heal", 0) + card.get("shield", 0)
		if power == 0:
			validation.warnings.append("Carta sin efecto: " + name)
		elif power > 25:
			validation.warnings.append("Carta posiblemente demasiado poderosa: " + name + " (poder: " + str(power) + ")")
	
	return validation
