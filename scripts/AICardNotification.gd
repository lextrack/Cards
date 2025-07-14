class_name AICardNotification
extends Control

@onready var background = $Background
@onready var card_name = $Background/VBox/CardName
@onready var card_effect = $Background/VBox/CardEffect
@onready var card_cost = $Background/VBox/CardCost

var tween: Tween
var is_showing: bool = false

func _ready():
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = 0.1 
	
	background.color = Color(0.1, 0.1, 0.1, 0.95)

func show_card_notification(card: CardData, player_name: String = "IA"):
	if is_showing:
		await hide_notification()
	
	is_showing = true
	
	card_name.text = player_name + " jugó: " + card.card_name
	card_cost.text = "Costo: " + str(card.cost) + " maná"
	
	
	match card.card_type:
		"attack":
			card_effect.text = "⚔️ Daño: " + str(card.damage)
			background.color = Color(0.9, 0.2, 0.2, 0.95)
		"heal":
			card_effect.text = "💚 Cura: " + str(card.heal)
			background.color = Color(0.2, 0.9, 0.2, 0.95)
		"shield":
			card_effect.text = "🛡️ Escudo: " + str(card.shield)
			background.color = Color(0.2, 0.4, 0.9, 0.95)
		_:
			card_effect.text = card.description
			background.color = Color(0.6, 0.6, 0.6, 0.95)
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
	tween.tween_property(self, "rotation", 0.0, 0.2)
	
	await tween.finished
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	await tween.finished
	await get_tree().create_timer(GameBalance.get_timer_delay("ai_card_popup")).timeout
	
	await hide_notification()

func hide_notification():
	if not is_showing:
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.15)
	tween.tween_property(self, "rotation", -0.05, 0.15)
	
	await tween.finished
	is_showing = false

func force_close():
	if tween:
		tween.kill()
	
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = 0.1
	is_showing = false
