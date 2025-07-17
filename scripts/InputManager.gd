class_name InputManager
extends RefCounted

var main_scene: Control
var gamepad_mode: bool = false
var last_input_was_gamepad: bool = false

func setup(main: Control):
	main_scene = main
	_setup_button_navigation()

func _setup_button_navigation():
	"""Configura la navegación de botones"""
	var end_turn_button = main_scene.end_turn_button
	if not end_turn_button:
		push_error("EndTurnButton no encontrado en la escena")
		return
		
	end_turn_button.pressed.connect(main_scene._on_end_turn_pressed)
	end_turn_button.focus_mode = Control.FOCUS_ALL
	
	end_turn_button.mouse_entered.connect(_on_button_hover.bind(end_turn_button))
	end_turn_button.focus_entered.connect(_on_button_focus.bind(end_turn_button))
	end_turn_button.mouse_exited.connect(_on_button_unhover.bind(end_turn_button))
	end_turn_button.focus_exited.connect(_on_button_unfocus.bind(end_turn_button))

func start_player_turn():
	"""Inicia el turno del jugador"""
	gamepad_mode = last_input_was_gamepad
	var end_turn_button = main_scene.end_turn_button
	
	if end_turn_button and gamepad_mode:
		end_turn_button.grab_focus()
	
	_update_controls_panel()
	main_scene.ui_manager.selected_card_index = 0
	main_scene.ui_manager.update_card_selection(gamepad_mode, main_scene.player)

func start_ai_turn():
	"""Inicia el turno de la IA"""
	gamepad_mode = false
	main_scene.ui_manager.update_hand_display(main_scene.player, main_scene.card_scene, main_scene.hand_container)

func handle_input(event: InputEvent):
	"""Maneja toda la entrada del usuario"""
	_detect_input_method(event)
	
	if event.is_action_pressed("gamepad_start"):
		_handle_controls_toggle()
	elif event.is_action_pressed("restart_game") or event.is_action_pressed("gamepad_restart"):
		main_scene.restart_game()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("gamepad_exit"):
		main_scene.show_exit_confirmation()
	elif main_scene.is_player_turn and gamepad_mode and main_scene.player:
		_handle_gamepad_navigation(event)

func _detect_input_method(event: InputEvent):
	"""Detecta si el input viene de gamepad o teclado/mouse"""
	if event is InputEventJoypadButton and event.pressed:
		if not last_input_was_gamepad:
			last_input_was_gamepad = true
			if main_scene.is_player_turn and main_scene.player:
				gamepad_mode = true
				_update_ui_for_gamepad_mode()
	elif event is InputEventMouse or (event is InputEventKey and event.pressed):
		if last_input_was_gamepad:
			last_input_was_gamepad = false
			if main_scene.is_player_turn and main_scene.player:
				gamepad_mode = false
				_update_ui_for_gamepad_mode()

func _update_ui_for_gamepad_mode():
	"""Actualiza la UI según el método de entrada"""
	main_scene.ui_manager.update_card_selection(gamepad_mode, main_scene.player)
	main_scene.ui_manager.update_turn_button_text(main_scene.player, main_scene.end_turn_button, gamepad_mode)
	_update_controls_panel()

func _update_controls_panel():
	"""Actualiza el panel de controles"""
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.update_gamepad_mode(gamepad_mode)

func _handle_controls_toggle():
	"""Maneja el toggle del panel de controles"""
	var controls_panel = main_scene.controls_panel
	if controls_panel and main_scene.is_player_turn:
		controls_panel.toggle_visibility()
		main_scene.audio_helper.play_card_hover_sound()

func _handle_gamepad_navigation(event: InputEvent):
	"""Maneja la navegación con gamepad"""
	if event.is_action_pressed("ui_left"):
		if main_scene.ui_manager.navigate_cards(-1, main_scene.player):
			main_scene.audio_helper.play_card_hover_sound()
	elif event.is_action_pressed("ui_right"):
		if main_scene.ui_manager.navigate_cards(1, main_scene.player):
			main_scene.audio_helper.play_card_hover_sound()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("gamepad_accept"):
		var selected_card = main_scene.ui_manager.get_selected_card()
		if selected_card:
			main_scene._on_card_clicked(selected_card)
	elif event.is_action_pressed("gamepad_cancel"):
		var end_turn_button = main_scene.end_turn_button
		if end_turn_button and not end_turn_button.disabled:
			main_scene._on_end_turn_pressed()

func _on_button_hover(button: Button):
	"""Maneja el hover de botones"""
	if not gamepad_mode:
		main_scene.audio_helper.play_card_hover_sound()

func _on_button_focus(button: Button):
	"""Maneja el focus de botones"""
	main_scene.audio_helper.play_card_hover_sound()
	
	var tween = main_scene.create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unhover(button: Button):
	"""Maneja cuando se quita el hover de botones"""
	if not gamepad_mode:
		var tween = main_scene.create_tween()
		tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _on_button_unfocus(button: Button):
	"""Maneja cuando se quita el focus de botones"""
	var tween = main_scene.create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
