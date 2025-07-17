extends Control

@onready var player_hp_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/HPStat/HPLabel
@onready var player_mana_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/ManaStat/ManaLabel
@onready var player_shield_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/ShieldStat/ShieldLabel
@onready var ai_hp_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/HPStat/HPLabel
@onready var ai_mana_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/ManaStat/ManaLabel
@onready var ai_shield_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/ShieldStat/ShieldLabel
@onready var hand_container = $UILayer/CenterArea/HandContainer
@onready var turn_label = $UILayer/TopPanel/StatsContainer/CenterInfo/TurnLabel
@onready var game_info_label = $UILayer/TopPanel/StatsContainer/CenterInfo/GameInfoLabel
@onready var end_turn_button = $UILayer/BottomPanel/TurnButtonsContainer/EndTurnButton
@onready var game_over_label = $UILayer/GameOverLabel
@onready var ui_layer = $UILayer
@onready var top_panel_bg = $UILayer/TopPanel/TopPanelBG
@onready var damage_bonus_label = $UILayer/TopPanel/StatsContainer/CenterInfo/DamageBonusLabel
@onready var audio_manager = $AudioManager

var ui_manager: UIManager
var game_manager: GameManager
var input_manager: InputManager
var audio_helper: AudioHelper
var confirmation_dialog: ExitConfirmationDialog

var card_scene = preload("res://scenes/Card.tscn")
var ai_notification_scene = preload("res://scenes/AICardNotification.tscn")
var game_notification_scene = preload("res://scenes/GameNotification.tscn")
@export var controls_panel_scene: PackedScene = preload("res://scenes/ControlsPanel.tscn")

var player: Player
var ai: Player
var ai_notification: AICardNotification
var game_notification: GameNotification
var controls_panel: ControlsPanel

var is_player_turn: bool = true
var difficulty: String = "normal"
var game_count: int = 1

func _ready():
	await initialize_game()

func initialize_game():
	_setup_components()
	_setup_notifications()
	_setup_controls_panel()
	_load_difficulty()
	
	if OS.is_debug_build():
		_validate_card_system()
	
	await handle_scene_entrance()
	setup_game()
	
func _validate_card_system():
	var validation = CardProbability.run_full_validation()
	
	if not validation.database_valid:
		print("❌ ERROR: Invalid card database:")
		for error in validation.errors:
			print("   ", error)
	
	if not validation.generation_working:
		print("❌ ERROR: Deck generation not working")
	
	if validation.warnings.size() > 0:
		print("⚠️  WARNINGS from card system:")
		for warning in validation.warnings:
			print("   ", warning)
	
	if validation.database_valid and validation.generation_working:
		print("✅ Card system validated successfully")
		
		var counts = CardDatabase.get_card_count()
		print("📊 Available cards: ", counts.total, " (", counts.attack, " attacks, ", counts.heal, " heals, ", counts.shield, " shields)")

func _setup_components():
	ui_manager = UIManager.new()
	ui_manager.setup(self)
	
	game_manager = GameManager.new()
	game_manager.setup(self)
	
	input_manager = InputManager.new()
	input_manager.setup(self)
	
	audio_helper = AudioHelper.new()
	audio_helper.setup(audio_manager)
	
	confirmation_dialog = ExitConfirmationDialog.new()
	confirmation_dialog.setup(self)

func _setup_notifications():
	ai_notification = ai_notification_scene.instantiate()
	game_notification = game_notification_scene.instantiate()
	add_child(ai_notification)
	add_child(game_notification)

func cleanup_notifications():
	if ai_notification:
		ai_notification.force_close()
	
	if game_notification:
		game_notification.clear_all_notifications()
	
	if controls_panel:
		controls_panel.force_hide()
	
	if OS.is_debug_build():
		print("Notifications cleaned up")

func _setup_controls_panel():
	controls_panel = controls_panel_scene.instantiate()
	ui_layer.add_child(controls_panel)

func _load_difficulty():
	difficulty = GameState.get_selected_difficulty()
	print("Starting game with difficulty: ", difficulty)

func handle_scene_entrance():
	await get_tree().process_frame
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		print("Main: TransitionManager and overlay available")
		if TransitionManager.current_overlay.has_method("is_ready") and TransitionManager.current_overlay.is_ready():
			await TransitionManager.current_overlay.fade_out(0.8)
		else:
			_play_direct_entrance()
	else:
		_play_direct_entrance()

func _play_direct_entrance():
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished

func setup_game():
	game_manager.setup_new_game(difficulty)
	player = game_manager.player
	ai = game_manager.ai
	
	_connect_player_signals()
	_connect_ai_signals()
	
	if OS.is_debug_build():
		_analyze_starting_decks()
	
	ui_manager.update_all_labels(player, ai)
	ui_manager.update_hand_display(player, card_scene, hand_container)
	start_player_turn()
	
func _analyze_starting_decks():
	print("\n🎴 BASIC DECK ANALYSIS:")
	
	if player:
		print("👤 PLAYER (", difficulty.to_upper(), "):")
		print("   Cards in deck: ", player.deck.size())
		print("   Cards in hand: ", player.hand.size())
		print("   Discarded cards: ", player.discard_pile.size())
		
		var attack_count = 0
		var heal_count = 0
		var shield_count = 0
		var all_cards = player.deck + player.hand + player.discard_pile
		
		for card in all_cards:
			if card is CardData:
				match card.card_type:
					"attack":
						attack_count += 1
					"heal":
						heal_count += 1
					"shield":
						shield_count += 1
		
		print("   Distribution: ", attack_count, " attacks, ", heal_count, " heals, ", shield_count, " shields")
	
	if ai:
		print("🤖 AI (", difficulty.to_upper(), "):")
		print("   Cards in deck: ", ai.deck.size())
		print("   Cards in hand: ", ai.hand.size())
		print("   Discarded cards: ", ai.discard_pile.size())
					
func debug_analyze_current_decks():
	if not OS.is_debug_build():
		print("Only available in debug builds")
		return
	
	print("\n🔍 CURRENT DECK ANALYSIS:")
	
	if player:
		print("👤 PLAYER:")
		player.debug_print_deck_info()
	
	if ai:
		print("\n🤖 AI:")
		ai.debug_print_deck_info()

func _connect_player_signals():
	player.hp_changed.connect(ui_manager.update_player_hp)
	player.mana_changed.connect(ui_manager.update_player_mana)
	player.shield_changed.connect(ui_manager.update_player_shield)
	player.player_died.connect(_on_player_died)
	player.hand_changed.connect(_on_player_hand_changed)
	player.deck_reshuffled.connect(_on_deck_reshuffled.bind("Player"))
	player.cards_played_changed.connect(_on_player_cards_played_changed)
	player.turn_changed.connect(_on_turn_changed)
	player.card_drawn.connect(_on_player_card_drawn)
	player.auto_turn_ended.connect(_on_auto_turn_ended)
	player.damage_taken.connect(_on_player_damage_taken)

func _connect_ai_signals():
	ai.hp_changed.connect(ui_manager.update_ai_hp)
	ai.mana_changed.connect(ui_manager.update_ai_mana)
	ai.shield_changed.connect(ui_manager.update_ai_shield)
	ai.player_died.connect(_on_ai_died)
	ai.deck_reshuffled.connect(_on_deck_reshuffled.bind("AI"))
	ai.ai_card_played.connect(_on_ai_card_played)

func start_player_turn():
	is_player_turn = true
	input_manager.start_player_turn()
	
	audio_helper.play_turn_change_sound(true)
	ui_manager.start_player_turn(player, difficulty)
	
	controls_panel.update_player_turn(true)
	controls_panel.update_cards_available(player.hand.size() > 0)

func start_ai_turn():
	is_player_turn = false
	input_manager.start_ai_turn()
	
	controls_panel.force_hide()
	audio_helper.play_turn_change_sound(false)
	ui_manager.start_ai_turn(ai)
	
	await ai.ai_turn(player)
	
	if game_manager.should_restart_for_no_cards():
		await game_manager.restart_for_no_cards()
		return
	
	await get_tree().create_timer(1.0).timeout
	start_player_turn()

func restart_game():
	cleanup_notifications()
	
	game_count += 1
	game_manager.restart_game(game_count, difficulty)
	audio_helper.play_background_music()
	
	await get_tree().create_timer(GameBalance.get_timer_delay("new_game")).timeout
	setup_game()

func _on_player_damage_taken(damage_amount: int):
	audio_helper.play_damage_sound(damage_amount)
	ui_manager.play_damage_effects(damage_amount)

func _on_player_hand_changed():
	ui_manager.update_hand_display(player, card_scene, hand_container)
	ui_manager.update_turn_button_text(player, end_turn_button, input_manager.gamepad_mode)
	
	if is_player_turn and player.get_hand_size() == 0:
		#game_notification.show_auto_end_turn_notification("no_cards")
		await game_manager.end_turn_no_cards()
		start_ai_turn()

func _on_player_cards_played_changed(cards_played: int, max_cards: int):
	ui_manager.update_hand_display(player, card_scene, hand_container)
	ui_manager.update_turn_button_text(player, end_turn_button, input_manager.gamepad_mode)
	ui_manager.update_cards_played_info(cards_played, max_cards, difficulty)
	
	if cards_played >= max_cards:
		#game_notification.show_auto_end_turn_notification("limit_reached")
		await game_manager.end_turn_limit_reached()
		start_ai_turn()
	elif is_player_turn and player.get_hand_size() == 0:
		#game_notification.show_auto_end_turn_notification("no_cards")
		await game_manager.end_turn_no_cards()
		start_ai_turn()

func _on_card_drawn(player_name: String, cards_count: int, from_deck: bool):
	audio_helper.play_card_draw_sound()
	game_notification.show_card_draw_notification(player_name, cards_count, from_deck)

func _on_player_card_drawn(cards_count: int, from_deck: bool):
	audio_helper.play_card_draw_sound()
	game_notification.show_card_draw_notification("Player", cards_count, from_deck)

func _on_turn_changed(turn_num: int, damage_bonus: int):
	if damage_bonus > 0 and GameBalance.is_damage_bonus_turn(turn_num):
		audio_helper.play_bonus_sound()
		game_notification.show_damage_bonus_notification(turn_num, damage_bonus)
	elif damage_bonus > 0:
		ui_manager.show_damage_bonus_info(turn_num, damage_bonus)
	
	ui_manager.update_all_labels(player, ai)
	ui_manager.update_damage_bonus_indicator(player, damage_bonus_label)

func _on_deck_reshuffled(player_name: String):
	audio_helper.play_deck_shuffle_sound()
	var cards_reshuffled = player.deck.size() if player_name == "Player" else ai.deck.size()
	game_notification.show_reshuffle_notification(player_name, cards_reshuffled)
	ui_manager.show_reshuffle_info(player_name)
	await get_tree().create_timer(2.0).timeout

func _on_auto_turn_ended(reason: String):
	game_notification.show_auto_end_turn_notification(reason)
	await get_tree().create_timer(0.5).timeout
	
	if game_manager.should_restart_for_no_cards():
		await game_manager.restart_for_no_cards()
		return
	
	start_ai_turn()

func _on_player_died():
	cleanup_notifications()
	audio_helper.play_lose_sound()
	GameState.add_game_result(false)
	game_notification.show_game_end_notification("Defeat", "hp_zero")
	await game_manager.handle_game_over("YOU LOST! Restarting...", end_turn_button)
	restart_game()

func _on_ai_card_played(card: CardData):
	audio_helper.play_card_play_sound(card.card_type)
	ai_notification.show_card_notification(card, "AI")

func _on_ai_died():
	cleanup_notifications()
	audio_helper.play_win_sound()
	GameState.add_game_result(true)
	game_notification.show_game_end_notification("Victory!", "hp_zero")
	await game_manager.handle_game_over("YOU WON! Restarting...", end_turn_button)
	restart_game()

func _on_card_clicked(card: Card):
	if not is_player_turn or not player.can_play_card(card.card_data):
		return
	
	audio_helper.play_card_play_sound(card.card_data.card_type)
	
	match card.card_data.card_type:
		"attack":
			player.play_card(card.card_data, ai)
		"heal", "shield":
			player.play_card(card.card_data)

func _on_end_turn_pressed():
	if not is_player_turn:
		return
		
	end_turn_button.release_focus()
	audio_helper.play_notification_sound()
	
	game_notification.show_auto_end_turn_notification("pass_turn")
	
	if game_manager.should_restart_for_no_cards():
		await game_manager.restart_for_no_cards()
		return
	
	start_ai_turn()

func _input(event):
	if confirmation_dialog.is_showing:
		confirmation_dialog.handle_input(event)
		return
	
	input_manager.handle_input(event)

func show_exit_confirmation():
	confirmation_dialog.show()

func return_to_menu():
	cleanup_notifications()
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 1.0)
