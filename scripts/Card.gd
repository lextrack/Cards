class_name Card
extends Control

@export var card_data: CardData
@onready var name_label = $CardBackground/VBox/NameLabel
@onready var cost_label = $CardBackground/VBox/CostLabel
@onready var description_label = $CardBackground/VBox/DescriptionLabel
@onready var card_background = $CardBackground

signal card_clicked(card: Card)

func _ready():
	if card_data:
		update_display()
	
	card_background.gui_input.connect(_on_card_input)

func update_display():
	name_label.text = card_data.card_name
	cost_label.text = "Costo: " + str(card_data.cost)
	
	# Añadir rareza a la descripción
	var rarity_text = DeckManager.get_card_rarity_text(card_data)
	description_label.text = card_data.description + "\n" + rarity_text
	
	# Color según rareza (más sutil) y tipo
	var base_color = Color.GRAY
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	
	# Color base según tipo
	match card_data.card_type:
		"attack":
			base_color = Color.RED
		"heal":
			base_color = Color.GREEN
		"shield":
			base_color = Color.BLUE
		_:
			base_color = Color.GRAY
	
	# Ajustar intensidad según rareza
	match rarity:
		"common":
			card_background.color = base_color * 0.7  # Más opaco
		"uncommon":
			card_background.color = base_color * 0.85
		"rare":
			card_background.color = base_color * 1.0   # Color normal
		"epic":
			card_background.color = base_color * 1.3   # Más brillante
		_:
			card_background.color = base_color

func _on_card_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(self)

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		update_display()
