class_name GameNotification
extends Control

@onready var background = $Background
@onready var notification_title = $Background/VBox/NotificationTitle
@onready var notification_text = $Background/VBox/NotificationText
@onready var notification_detail = $Background/VBox/NotificationDetail

var tween: Tween
var is_showing: bool = false
var notification_queue: Array = []

func _ready():
	modulate.a = 0.0
	scale = Vector2(0.7, 0.7)
	rotation = deg_to_rad(5)
	
	background.color = Color(0.15, 0.15, 0.25, 0.95)

func show_notification(title: String, text: String, detail: String, color: Color, duration: float):
	if is_showing:
		await hide_notification()
	
	is_showing = true
	
	notification_title.text = title
	notification_text.text = text
	notification_detail.text = detail
	background.color = color
	
	if tween:
		tween.kill()
	
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.7, 0.7)
	rotation = deg_to_rad(5)
	
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "rotation", deg_to_rad(0), 0.25)
	
	await tween.finished
	
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	await tween.finished
	await get_tree().create_timer(duration).timeout

	await hide_notification()
	
	if notification_queue.size() > 0:
		await get_tree().create_timer(0.3).timeout
		process_next_notification()

func hide_notification():
	if not is_showing:
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(-3), 0.2).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	is_showing = false
	visible = false

func show_card_draw_notification(player_name: String, cards_drawn: int, from_deck: bool = true):
	var title = player_name + " sacó carta" + ("s" if cards_drawn > 1 else "")
	var text = ""
	var detail = ""
	var color = Color(0.2, 0.6, 0.9, 0.95)
	
	if from_deck:
		text = "📥 " + str(cards_drawn) + " carta" + ("s" if cards_drawn > 1 else "") + " del mazo"
		detail = "Nuevas opciones disponibles"
	else:
		text = "🔄 Mano inicial: " + str(cards_drawn) + " cartas"
		detail = "¡Que comience la batalla!"
	
	queue_notification(title, text, detail, color, GameBalance.get_timer_delay("notification_draw"))

func show_reshuffle_notification(player_name: String, cards_reshuffled: int):
	var title = player_name + " remezcló las cartas"
	var text = "♻️ " + str(cards_reshuffled) + " cartas al mazo"
	var detail = "¡Cartas usadas vuelven a estar disponibles!"
	var color = Color(0.8, 0.6, 0.2, 0.95)
	
	queue_notification(title, text, detail, color, GameBalance.get_timer_delay("notification_reshuffle"))

func show_auto_end_turn_notification(reason: String):
	var title = "Turno terminado automáticamente"
	var text = ""
	var detail = ""
	var color = Color(0.6, 0.6, 0.6, 0.95)
	
	match reason:
		"no_cards":
			text = "🚫 Sin cartas en mano"
			detail = "No hay más cartas para jugar"
		"limit_reached":
			text = "🎯 Límite de cartas alcanzado"
			detail = "Ya jugaste todas las cartas permitidas"
		"no_mana":
			text = "⚡ Sin maná suficiente"
			detail = "Ninguna carta se puede jugar"
		"pass_turn":
			title = "Turno pasado"
			text = "⏭️ Decidiste pasar el turno"
			detail = "Sin cartas jugadas"
			color = Color(0.4, 0.7, 0.9, 0.95)
	
	queue_notification(title, text, detail, color, GameBalance.get_timer_delay("notification_auto_turn"))

func show_damage_bonus_notification(turn_number: int, bonus: int):
	var title = "¡Bonus de daño activado!"
	var text = "⚔️ +" + str(bonus) + " de daño a todos los ataques"
	var detail = "Turno " + str(turn_number)
	var color = Color(0.9, 0.3, 0.1, 0.95)
	
	queue_notification(title, text, detail, color, GameBalance.get_timer_delay("notification_bonus"))

func show_game_end_notification(winner: String, reason: String):
	var title = winner + " Has ganado"
	var text = ""
	var detail = "Nueva partida comenzando..."
	var color = Color(0.2, 0.8, 0.2, 0.95)
	
	match reason:
		"hp_zero":
			text = "💀 HP reducido a 0"
		"no_cards":
			text = "🃏 Sin cartas disponibles"
	
	if winner == "Derrota":
		color = Color(0.8, 0.2, 0.2, 0.95)
	
	queue_notification(title, text, detail, color, GameBalance.get_timer_delay("notification_end"))

func queue_notification(title: String, text: String, detail: String, color: Color, duration: float):
	var notification = {
		"title": title,
		"text": text,
		"detail": detail,
		"color": color,
		"duration": duration
	}
	
	notification_queue.append(notification)
	
	if not is_showing:
		process_next_notification()

func process_next_notification():
	if notification_queue.size() == 0:
		return
	
	var notification = notification_queue.pop_front()
	show_notification(notification.title, notification.text, notification.detail, notification.color, notification.duration)

func clear_all_notifications():
	notification_queue.clear()
	if tween:
		tween.kill()
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = 0.0
	is_showing = false
