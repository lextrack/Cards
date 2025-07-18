extends Control

@onready var play_button = $MenuContainer/ButtonsContainer/PlayButton
@onready var options_button = $MenuContainer/ButtonsContainer/OptionsButton
@onready var help_button = $MenuContainer/ButtonsContainer/HelpButton
@onready var credits_button = $MenuContainer/ButtonsContainer/CreditsButton
@onready var exit_button = $MenuContainer/ButtonsContainer/ExitButton
@onready var stats_button = $MenuContainer/ButtonsContainer/StatsButton

@onready var game_title = $MenuContainer/TitleContainer/GameTitle
@onready var version_label: Label = $FooterContainer/VersionLabel
@onready var transition_layer = $TransitionLayer
@onready var transition_label = $TransitionLayer/TransitionLabel

@onready var menu_music_player = $AudioManager/MenuMusicPlayer
@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

var is_transitioning: bool = false
var music_fade_tween: Tween

func _ready():
	setup_buttons()
	setup_audio()
	
	await handle_scene_entrance()

	start_menu_music()
	
	play_button.grab_focus()

func setup_audio():
	if menu_music_player and menu_music_player.stream and GlobalMusicManager:
		if not GlobalMusicManager.menu_music_player.stream:
			GlobalMusicManager.set_menu_music_stream(menu_music_player.stream)
		else:
			print("🎵 Menu music stream already configured in GlobalMusicManager")

func start_menu_music():
	if GlobalMusicManager:
		GlobalMusicManager.start_menu_music()
	else:
		print("⚠️ GlobalMusicManager not available")

func stop_menu_music(fade_duration: float = 1.0):
	if GlobalMusicManager:
		GlobalMusicManager.stop_menu_music_for_game(fade_duration)
	else:
		print("⚠️ GlobalMusicManager not available")

func resume_menu_music():
	start_menu_music()

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		print("MainMenu: TransitionManager available")
		
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
	help_button.pressed.connect(_on_help_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	stats_button.pressed.connect(_on_statistics_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	var buttons = [play_button, options_button, help_button, credits_button, stats_button, exit_button]
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.focus_entered.connect(_on_button_focus.bind(button))
		
func _on_statistics_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/StatisticsMenu.tscn", 1.0)

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(5.0, 1.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.8)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.6)
	
	await tween.finished
	animate_title()

func animate_title():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(game_title, "modulate", Color(1.2, 1.2, 0.9, 1.0), 2.0)
	tween.tween_property(game_title, "modulate", Color(1.0, 1.0, 0.8, 1.0), 2.0)

func _on_play_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")

	stop_menu_music(0.8)
	await get_tree().create_timer(0.3).timeout

	TransitionManager.fade_to_scene("res://scenes/DifficultyMenu.tscn", 1.0)

func _on_help_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/HelpMenu.tscn", 1.0)

func _on_options_pressed():
	if is_transitioning:
		return
	
	play_ui_sound("button_click")	
	show_coming_soon("Coming soon. [Press ESC or B in gamepad to close]")

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
	play_hover_sound()
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	
	if not button.focus_exited.is_connected(_on_button_unfocus):
		button.focus_exited.connect(_on_button_unfocus.bind(button))

func _on_button_unfocus(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func show_coming_soon(message: String):
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
	
	🎵 Audio:
			freesound.org: 
	Raclure, Diasyl, Loyalty_Freak_Music,
	designerschoice, BeezleFM
	
	🎨 Art:
	Icons from Flaticon
	
	[Press ESC or B in gamepad to close]
	"""
	
	transition_label.text = credits_text
	transition_layer.visible = true
	transition_layer.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.9, 0.3)

func exit_game():
	is_transitioning = true
	
	stop_menu_music(0.5)
	
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
	match sound_type:
		"button_click":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
			pass
		_:
			pass

func play_hover_sound():
	pass

func _input(event):
	if is_transitioning:
		return
		
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("gamepad_cancel"):
		if transition_layer.visible and transition_layer.modulate.a > 0.5:
			hide_popup()
		else:
			_on_exit_pressed()
	
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("gamepad_accept"):
		if play_button.has_focus():
			_on_play_pressed()
		elif options_button.has_focus():
			_on_options_pressed()
		elif help_button.has_focus():
			_on_help_pressed()
		elif credits_button.has_focus():
			_on_credits_pressed()
		elif stats_button.has_focus():
			_on_statistics_pressed()
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

func set_background_color(color: Color):
	$BackgroundLayer/BackgroundGradient.color = color

func _on_scene_entered():
	resume_menu_music()
