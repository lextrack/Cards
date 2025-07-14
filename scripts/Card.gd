class_name Card
extends Control

@export var card_data: CardData
@onready var name_label = $CardBackground/VBox/HeaderContainer/NameLabel
@onready var cost_label = $CardBackground/VBox/HeaderContainer/CostContainer/CostLabel
@onready var cost_bg = $CardBackground/VBox/HeaderContainer/CostContainer/CostBG
@onready var description_label = $CardBackground/VBox/DescriptionContainer/DescriptionLabel
@onready var card_background = $CardBackground
@onready var card_bg = $CardBackground/CardBG
@onready var card_border = $CardBackground/CardBorder
@onready var card_inner = $CardBackground/CardInner
@onready var card_icon = $CardBackground/VBox/ArtContainer/CardIcon
@onready var stat_value = $CardBackground/VBox/StatsContainer/StatValue
@onready var stat_icon = $CardBackground/VBox/StatsContainer/StatIcon
@onready var rarity_label = $CardBackground/VBox/RarityContainer/RarityLabel
@onready var rarity_bg = $CardBackground/VBox/RarityContainer/RarityBG
@onready var art_bg = $CardBackground/VBox/ArtContainer/ArtBG

signal card_clicked(card: Card)

var original_scale: Vector2
var is_hovered: bool = false

func _ready():
	original_scale = scale
	if card_data:
		update_display()
	
	# Conectar eventos de input y mouse al nodo principal Card
	gui_input.connect(_on_card_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Asegurar que todos los elementos hijos no bloqueen eventos de mouse
	set_mouse_filter_recursive(self)

func update_display():
	name_label.text = card_data.card_name
	cost_label.text = str(card_data.cost)
	
	# Añadir rareza a la descripción
	var rarity_text = DeckManager.get_card_rarity_text(card_data)
	description_label.text = card_data.description
	rarity_label.text = rarity_text
	
	# Configurar colores y iconos según tipo de carta
	var type_colors = get_card_type_colors(card_data.card_type)
	var rarity_colors = get_rarity_colors()
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	
	# Aplicar colores base
	card_bg.color = type_colors.background
	card_border.color = type_colors.border
	card_inner.color = type_colors.inner
	cost_bg.color = type_colors.cost_bg
	art_bg.color = type_colors.art_bg
	
	# Aplicar brillo de rareza
	var rarity_multiplier = rarity_colors[rarity]
	card_border.color = card_border.color * rarity_multiplier
	rarity_bg.color = type_colors.border * 0.8
	
	# Efectos especiales según rareza
	apply_rarity_effects(rarity)
	
	# Configurar icono y estadísticas
	match card_data.card_type:
		"attack":
			card_icon.text = "⚔️"
			stat_value.text = str(card_data.damage)
			stat_icon.text = "💥"
			stat_value.modulate = Color.ORANGE_RED
		"heal":
			card_icon.text = "💚"
			stat_value.text = str(card_data.heal)
			stat_icon.text = "❤️"
			stat_value.modulate = Color.LIME_GREEN
		"shield":
			card_icon.text = "🛡️"
			stat_value.text = str(card_data.shield)
			stat_icon.text = "🔰"
			stat_value.modulate = Color.CYAN
		_:
			card_icon.text = "❓"
			stat_value.text = "?"
			stat_icon.text = "❓"
			stat_value.modulate = Color.GRAY

func get_card_type_colors(card_type: String) -> Dictionary:
	match card_type:
		"attack":
			return {
				"background": Color(0.2, 0.1, 0.1, 1),
				"border": Color(0.8, 0.2, 0.2, 1),
				"inner": Color(0.3, 0.15, 0.15, 1),
				"cost_bg": Color(0.6, 0.1, 0.1, 1),
				"art_bg": Color(0.4, 0.2, 0.2, 1)
			}
		"heal":
			return {
				"background": Color(0.1, 0.2, 0.1, 1),
				"border": Color(0.2, 0.8, 0.2, 1),
				"inner": Color(0.15, 0.3, 0.15, 1),
				"cost_bg": Color(0.1, 0.6, 0.1, 1),
				"art_bg": Color(0.2, 0.4, 0.2, 1)
			}
		"shield":
			return {
				"background": Color(0.1, 0.1, 0.2, 1),
				"border": Color(0.2, 0.4, 0.8, 1),
				"inner": Color(0.15, 0.15, 0.3, 1),
				"cost_bg": Color(0.1, 0.2, 0.6, 1),
				"art_bg": Color(0.2, 0.2, 0.4, 1)
			}
		_:
			return {
				"background": Color(0.15, 0.15, 0.15, 1),
				"border": Color(0.5, 0.5, 0.5, 1),
				"inner": Color(0.25, 0.25, 0.25, 1),
				"cost_bg": Color(0.4, 0.4, 0.4, 1),
				"art_bg": Color(0.3, 0.3, 0.3, 1)
			}

func get_rarity_colors() -> Dictionary:
	return {
		"common": 1.0,
		"uncommon": 1.4,  # Más notable
		"rare": 1.8,      # Más brillante
		"epic": 2.5       # Muy brillante
	}

func _on_card_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(self)

func _on_mouse_entered():
	if not is_hovered:
		is_hovered = true
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", original_scale * 1.1, 0.2)
		tween.tween_property(self, "z_index", 10, 0.1)

func _on_mouse_exited():
	if is_hovered:
		is_hovered = false
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", original_scale, 0.2)
		tween.tween_property(self, "z_index", 0, 0.1)

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		update_display()
		# Reproducir animación especial para cartas épicas
		call_deferred("play_epic_entrance_animation")

func set_playable(playable: bool):
	if playable:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.8)

# Función para asegurar que todos los elementos hijos permitan eventos de mouse
func set_mouse_filter_recursive(node: Node):
	if node is Control:
		var control = node as Control
		# Permitir que el evento pase a través de todos los elementos hijos
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	
	for child in node.get_children():
		set_mouse_filter_recursive(child)

# Efectos especiales según rareza
func apply_rarity_effects(rarity: String):
	match rarity:
		"uncommon":
			# Brillo sutil en el nombre
			name_label.modulate = Color(1.2, 1.2, 1.0, 1.0)
			# Efecto en el costo
			cost_label.modulate = Color(1.3, 1.3, 1.0, 1.0)
		"rare":
			# Brillo dorado en elementos clave
			name_label.modulate = Color(1.4, 1.3, 0.8, 1.0)
			cost_label.modulate = Color(1.5, 1.4, 0.7, 1.0)
			stat_value.modulate = stat_value.modulate * Color(1.3, 1.2, 0.9, 1.0)
			# Efecto en el icono
			card_icon.modulate = Color(1.2, 1.15, 0.95, 1.0)
		"epic":
			# Efectos muy notorios - colores púrpura/dorado
			name_label.modulate = Color(1.8, 1.4, 2.0, 1.0)  # Púrpura brillante
			cost_label.modulate = Color(2.0, 1.5, 0.5, 1.0)  # Dorado intenso
			stat_value.modulate = stat_value.modulate * Color(1.8, 1.3, 0.6, 1.0)
			card_icon.modulate = Color(1.5, 1.2, 1.8, 1.0)   # Púrpura suave
			# Brillo adicional en toda la carta
			modulate = Color(1.1, 1.05, 1.15, 1.0)
		_:
			# Cartas comunes - colores normales
			pass

# Animación especial para cartas épicas al aparecer
func play_epic_entrance_animation():
	if not card_data:
		return
	
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	if rarity == "epic":
		# Efecto de pulso dorado
		var tween = create_tween()
		tween.set_loops(3)
		tween.set_parallel(true)
		
		# Pulso de escala
		tween.tween_property(self, "scale", original_scale * 1.15, 0.3)
		tween.tween_property(self, "scale", original_scale, 0.3)
		
		# Pulso de brillo
		var original_modulate = modulate
		tween.tween_property(self, "modulate", Color(1.3, 1.1, 1.4, 1.0), 0.3)
		tween.tween_property(self, "modulate", original_modulate, 0.3)
