extends Control

@onready var topics_buttons_container = $MainContainer/ContentContainer/TopicsPanel/TopicsContainer/TopicsButtonsContainer
@onready var content_label = $MainContainer/ContentContainer/ContentPanel/ContentScrollContainer/ContentLabel
@onready var back_button = $MainContainer/ButtonsContainer/BackButton
@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

var is_transitioning: bool = false
var selected_topic_button: Button = null

var help_topics = {
	"📖 Reglas Básicas": """[font_size=24][color=yellow]⚔️ REGLAS DEL JUEGO[/color][/font_size]

[font_size=18][color=lightblue]🎯 OBJETIVO:[/color][/font_size]
Reduce la vida del oponente a 0 para ganar la partida.

[font_size=18][color=lightblue]🎮 TURNOS:[/color][/font_size]
• Cada turno recibes maná completo y robas cartas
• Puedes jugar cartas pagando su costo de maná
• Tienes un límite de cartas por turno (según dificultad)
• Al terminar tu turno, el oponente juega

[font_size=18][color=lightblue]💎 RECURSOS:[/color][/font_size]
• [color=red]VIDA[/color]: Si llega a 0, pierdes la partida
• [color=cyan]MANÁ[/color]: Se usa para jugar cartas, se regenera cada turno
• [color=orange]CARTAS[/color]: Tu arsenal: según la dificultad, puedes usar hasta 4 o 5 cartas por turno. Las especiales brillan más
• [color=white]MAZOS[/color]: Cantidad de cartas disponible (se repone automáticamente, nunca te faltan)""",

	"🃏 Tipos de Cartas": """[font_size=24][color=yellow]🗂️ TIPOS DE CARTAS[/color][/font_size]

[font_size=18][color=red]⚔️ CARTAS DE ATAQUE:[/color][/font_size]
• Causan daño directo al oponente
• Primero afectan el escudo, luego la vida
• Ejemplos de ese tipo: Golpe Básico (1 daño), Espada Afilada (5 daño)

[font_size=18][color=green]💚 CARTAS DE CURACIÓN:[/color][/font_size]
• Restauran tu vida perdida
• Puedes usarlos incluso excediendo tu vida máxima
• Ejemplos: Vendaje (2 vida), Poción Mayor (8 vida)

[font_size=18][color=cyan]🛡️ CARTAS DE ESCUDO:[/color][/font_size]
• Absorben el daño recibido
• Se acumulan si usas varias seguidas
• No se regeneran automáticamente
• Ejemplos: Bloqueo (2 escudo), Escudo Reforzado (6 escudo)""",

	"⭐ Sistema de Rareza": """[font_size=24][color=yellow]💎 RAREZA DE CARTAS[/color][/font_size]

[font_size=18][color=white]⚪ COMUNES (Blancas):[/color][/font_size]
• Cartas básicas y equilibradas
• Aparecen frecuentemente
• Efectos simples pero útiles
• Ejemplo: Golpe Básico, Vendaje

[font_size=18][color=green]🟢 POCO COMUNES (Verdes):[/color][/font_size]
• Efectos más potentes que las comunes
• Aparecen ocasionalmente
• Mayor brillo visual
• Ejemplo: Espada Afilada, Poción

[font_size=18][color=cyan]🔵 RARAS (Azules):[/color][/font_size]
• Cartas muy poderosas
• Solo a veces aparecen
• Brillo azul distintivo
• Ejemplo: Golpe Crítico, Curación Mayor

[font_size=18][color=magenta]🟣 ÉPICAS (Púrpuras):[/color][/font_size]
• Las más poderosas del juego
• Efectos devastadores
• Ejemplo: Aniquilación (20 daño), Regeneración (12 vida)""",

	"🎚️ Niveles de Dificultad": """[font_size=24][color=yellow]⚖️ DIFICULTADES DISPONIBLES[/color][/font_size]

[font_size=18][color=green]🟢 NORMAL:[/color][/font_size]
[color=lightblue]👤 Jugador:[/color] 35 HP, 10 Maná, 2 cartas/turno, 5 en mano
[color=orange]🤖 IA:[/color] 35 HP, 10 Maná, estrategia equilibrada

[font_size=18][color=orange]🟠 DIFÍCIL:[/color][/font_size]
[color=lightblue]👤 Jugador:[/color] 33 HP, 10 Maná, 1 carta/turno, 5 en mano
[color=orange]🤖 IA:[/color] 35 HP, 10 Maná, estrategia agresiva

[font_size=18][color=red]🔴 EXPERTO:[/color][/font_size]
[color=lightblue]👤 Jugador:[/color] 30 HP, 8 Maná, 1 carta/turno, 4 en mano
[color=orange]🤖 IA:[/color] 38 HP, 12 Maná, estrategia brutal""",

	"⚔️ Sistema de Combate": """[font_size=24][color=yellow]🎲 MECÁNICAS DE COMBATE[/color][/font_size]

[font_size=18][color=cyan]💥 DAÑO Y ESCUDO:[/color][/font_size]
• El escudo absorbe daño antes que la vida
• Si el daño es mayor que el escudo, la diferencia va a vida
• Acumula escudos usando múltiples cartas

[font_size=18][color=red]🔥 BONUS DE DAÑO:[/color][/font_size]
• [color=orange]Turno 4:[/color] +1 daño a todos los ataques
• [color=orange]Turno 7:[/color] +2 daño a todos los ataques  
• [color=orange]Turno 10:[/color] +3 daño a todos los ataques
• [color=orange]Turno 15+:[/color] +4 daño a todos los ataques
• Al superar esos niveles, el bonus se aplica automáticamente a todos los contendientes

[font_size=18][color=green]🔄 RECICLAJE DE CARTAS:[/color][/font_size]
• Cuando se agota el mazo, las cartas usadas se reintegran
• Nunca te quedarás completamente sin opciones
• La estrategia cambia según las cartas disponibles
• En general, el reciclaje y retiro/robo de cartas es automático, no debes hacer nada""",

"🎮 Controles": """[font_size=24][color=yellow]🕹️ CONTROLES DEL JUEGO[/color][/font_size]

[font_size=18][color=orange]🎯 PARA NAVEGAR:[/color][/font_size]

[font_size=18][color=white]⌨️ TECLADO:[/color][/font_size]
- [color=cyan]Flechas:[/color] Navegar por menús y cartas
- [color=cyan]Enter:[/color] Confirmar selección
- [color=cyan]Escape:[/color] Cancelar/Volver/Menú principal

[font_size=18][color=white]🎮 MANDO:[/color][/font_size]
- [color=cyan]D-Pad/Stick izquierdo:[/color] Navegación de menús y cartas
- [color=cyan]Botón A:[/color] Confirmar/Seleccionar
- [color=cyan]Botón B:[/color] Cancelar/Volver

[font_size=18][color=orange]🎯 CONTROLES EN PARTIDA:[/color][/font_size]
[color=white]Con Mando:[/color]
- [color=lime]Izquierda/Derecha:[/color] Navegar entre cartas
- [color=lime]A:[/color] Jugar carta seleccionada
- [color=lime]B:[/color] Terminar turno
- [color=lime]X:[/color] Reiniciar partida
- [color=lime]Y:[/color] Salir al menú principal

[color=white]Con Teclado/Ratón:[/color]
- [color=lime]Click en carta:[/color] Jugar carta
- [color=lime]Click en "Terminar Turno":[/color] Finalizar turno
- [color=lime]R:[/color] Reiniciar partida
- [color=lime]ESC:[/color] Salir al menú principal"""
}

func _ready():
	setup_topics()
	setup_buttons()
	
	await handle_scene_entrance()
	
	if topics_buttons_container.get_child_count() > 0:
		topics_buttons_container.get_child(0).grab_focus()

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and 
			TransitionManager.current_overlay.is_ready() and 
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):
			
			await TransitionManager.current_overlay.fade_out(0.3)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

func setup_topics():
	var first_topic = true
	
	for topic_name in help_topics.keys():
		var topic_button = Button.new()
		topic_button.text = topic_name
		topic_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		topic_button.custom_minimum_size.y = 45
		topic_button.add_theme_font_size_override("font_size", 14)
		topic_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		topics_buttons_container.add_child(topic_button)
		
		topic_button.pressed.connect(_on_topic_selected.bind(topic_name, topic_button))
		topic_button.mouse_entered.connect(_on_button_hover.bind(topic_button))
		topic_button.focus_entered.connect(_on_button_focus.bind(topic_button))
		
		if first_topic:
			_on_topic_selected(topic_name, topic_button)
			first_topic = false

func setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(_on_button_hover.bind(back_button))
	back_button.focus_entered.connect(_on_button_focus.bind(back_button))

func _on_topic_selected(topic_name: String, button: Button):
	if selected_topic_button:
		selected_topic_button.modulate = Color.WHITE
	
	selected_topic_button = button
	button.modulate = Color(1.2, 1.2, 0.8, 1)
	
	content_label.text = help_topics[topic_name]
	
	play_ui_sound("select")

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 0.8)

func _on_button_hover(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.1)
	
	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	play_hover_sound()

func play_ui_sound(sound_type: String):
	match sound_type:
		"button_click", "select":
			if ui_player.stream != preload("res://audio/ui/button_click.wav"):
				ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
		_:
			pass

func play_hover_sound():
	pass

func _input(event):
	if is_transitioning:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("gamepad_cancel"):
		_on_back_pressed()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("gamepad_accept"):
		if back_button.has_focus():
			_on_back_pressed()
		else:
			for child in topics_buttons_container.get_children():
				if child.has_focus():
					child.pressed.emit()
					break
