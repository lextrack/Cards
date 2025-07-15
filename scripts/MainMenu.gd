extends Control

# Referencias a los botones
@onready var play_button = $MenuContainer/ButtonsContainer/PlayButton
@onready var options_button = $MenuContainer/ButtonsContainer/OptionsButton
@onready var credits_button = $MenuContainer/ButtonsContainer/CreditsButton
@onready var exit_button = $MenuContainer/ButtonsContainer/ExitButton

# Referencias a elementos visuales
@onready var game_title = $MenuContainer/TitleContainer/GameTitle
@onready var version_label = $MenuContainer/FooterContainer/VersionLabel
@onready var transition_layer = $TransitionLayer
@onready var transition_label = $TransitionLayer/TransitionLabel

# Audio
@onready var menu_music_player = $AudioManager/MenuMusicPlayer
@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

# Variables de estado
var is_transitioning: bool = false

func _ready():
	setup_buttons()
	setup_audio()
	
	# Manejar entrada suave desde TransitionManager
	await handle_scene_entrance()
	
	# Focus en el primer botón para navegación con teclado
	play_button.grab_focus()

func handle_scene_entrance():
	await get_tree().process_frame
	
	# Verificar si hay TransitionManager y overlay disponible
	if TransitionManager and TransitionManager.current_overlay:
		print("MainMenu: TransitionManager disponible")
		
		if (TransitionManager.current_overlay.has_method("is_ready") and 
			TransitionManager.current_overlay.is_ready() and 
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):

			await TransitionManager.current_overlay.fade_out(0.8)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func setup_buttons():
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	var buttons = [play_button, options_button, credits_button, exit_button]
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.focus_entered.connect(_on_button_focus.bind(button))

func setup_audio():
	# Aquí puedes asignar música de menú si tienes
	# menu_music_player.stream = preload("res://audio/music/menu_music.ogg")
	# menu_music_player.play()
	pass

func play_entrance_animation():
	# Empezar invisible
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	
	# Animar entrada
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.8)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.6)
	
	# Animar título con efecto especial
	await tween.finished
	animate_title()

func animate_title():
	"""Animación especial para el título"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(game_title, "modulate", Color(1.2, 1.2, 0.9, 1.0), 2.0)
	tween.tween_property(game_title, "modulate", Color(1.0, 1.0, 0.8, 1.0), 2.0)

# === EVENTOS DE BOTONES ===

func _on_play_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	# Usar TransitionManager para transición suave
	TransitionManager.fade_to_scene("res://scenes/Main.tscn", 1.2, "Iniciando partida...")

func _on_options_pressed():
	if is_transitioning:
		return
	
	play_ui_sound("button_click")
	# Por ahora, mostrar mensaje de "próximamente"
	show_coming_soon("Menú de opciones próximamente")
	
	# Cuando tengas el menú de opciones:
	# is_transitioning = true
	# TransitionManager.fade_to_scene("res://scenes/OptionsMenu.tscn", 1.0, "Cargando opciones...")

func _on_credits_pressed():
	if is_transitioning:
		return
	
	play_ui_sound("button_click")
	show_credits_popup()

func _on_exit_pressed():
	if is_transitioning:
		return
	
	play_ui_sound("button_click")
	exit_game()

func _on_button_hover(button: Button):
	"""Efecto visual y sonoro al pasar mouse sobre botón"""
	play_hover_sound()
	
	# Efecto visual de hover
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	
	# Restaurar escala cuando el mouse sale
	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	"""Restaura el botón cuando el mouse sale"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	"""Efecto cuando el botón recibe focus (navegación con teclado)"""
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	
	if not button.focus_exited.is_connected(_on_button_unfocus):
		button.focus_exited.connect(_on_button_unfocus.bind(button))

func _on_button_unfocus(button: Button):
	"""Restaura el botón cuando pierde focus"""
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

# === TRANSICIONES LOCALES (para popups del menú) ===

func show_coming_soon(message: String):
	"""Muestra mensaje de 'próximamente'"""
	transition_label.text = message
	transition_layer.visible = true
	transition_layer.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.8, 0.3)
	
	await tween.finished
	await get_tree().create_timer(1.5).timeout
	
	tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	transition_layer.visible = false

func show_credits_popup():
	var credits_text = """
	🎮 CARD MASTER
	
	Desarrollado por: Lextrack
	
	🎵 Audio:
	Efectos de sonido de freesound.org
	
	🎨 Arte:
	Iconos de la comunidad
	
	[Presiona ESC para cerrar]
	"""
	
	transition_label.text = credits_text
	transition_layer.visible = true
	transition_layer.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.9, 0.3)

func exit_game():
	"""Sale del juego con animación suave"""
	is_transitioning = true
	
	# Usar TransitionManager para salida suave
	if TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.8)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_property(transition_layer, "modulate:a", 1.0, 0.5)
		await tween.finished
	
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func play_ui_sound(sound_type: String):
	"""Reproduce sonido de UI"""
	match sound_type:
		"button_click":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
			pass
		_:
			pass

func play_hover_sound():
	"""Reproduce sonido de hover"""
	# hover_player.stream = preload("res://audio/ui/hover.wav")
	# hover_player.play()
	pass

func _input(event):
	if is_transitioning:
		return
		
	if event.is_action_pressed("ui_cancel"):
		if transition_layer.visible and transition_layer.modulate.a > 0.5:
			hide_popup()
		else:
			_on_exit_pressed()
	
	elif event.is_action_pressed("ui_accept"):
		# Enter para comenzar partida
		if play_button.has_focus():
			_on_play_pressed()
		elif options_button.has_focus():
			_on_options_pressed()
		elif credits_button.has_focus():
			_on_credits_pressed()
		elif exit_button.has_focus():
			_on_exit_pressed()

func hide_popup():
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.0, 0.3)
	await tween.finished
	transition_layer.visible = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		exit_game()

func set_version_text(version: String):
	version_label.text = "Versión " + version + " - Ariel Alejandro Muñoz (Lextrack)"

func set_background_color(color: Color):
	$BackgroundLayer/BackgroundGradient.color = color
