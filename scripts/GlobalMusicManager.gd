extends Node

var menu_music_player: AudioStreamPlayer
var game_music_player: AudioStreamPlayer
var current_music_type: String = ""
var music_fade_tween: Tween

func _ready():
	_create_music_players()

func _create_music_players():
	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.name = "GlobalMenuMusicPlayer"
	menu_music_player.volume_db = -8.0
	menu_music_player.finished.connect(_on_menu_music_finished)
	add_child(menu_music_player)
	
	game_music_player = AudioStreamPlayer.new()
	game_music_player.name = "GlobalGameMusicPlayer"
	game_music_player.volume_db = -25.0
	add_child(game_music_player)

func _on_menu_music_finished():
	if current_music_type == "menu" and menu_music_player.stream:
		menu_music_player.play()

func set_menu_music_stream(stream: AudioStream):
	if menu_music_player and not menu_music_player.stream:
		menu_music_player.stream = stream
	elif menu_music_player and menu_music_player.stream:
		print("🎵 Menu music stream already set, skipping")

func set_game_music_stream(stream: AudioStream):
	if game_music_player and not game_music_player.stream:
		game_music_player.stream = stream
	elif game_music_player and game_music_player.stream:
		print("🎵 Game music stream already set, skipping")

func start_menu_music(fade_duration: float = 1.5):
	if current_music_type == "menu" and menu_music_player and menu_music_player.playing:
		return

	if current_music_type == "game" and game_music_player and game_music_player.playing:
		stop_all_music(0.5)
		await get_tree().create_timer(0.3).timeout
	
	if not menu_music_player or not menu_music_player.stream:
		print("⚠️ GlobalMusicManager: No menu music stream available")
		return
	
	current_music_type = "menu"
	
	menu_music_player.volume_db = -40.0
	menu_music_player.play()
	
	if music_fade_tween:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(menu_music_player, "volume_db", -8.0, fade_duration)

func start_game_music(fade_duration: float = 1.5):
	if current_music_type == "game" and game_music_player.playing:
		return
	
	stop_all_music(0.5)
	await get_tree().create_timer(0.3).timeout
	
	if not game_music_player or not game_music_player.stream:
		return
	
	current_music_type = "game"
	
	game_music_player.volume_db = -40.0
	game_music_player.play()
	
	if music_fade_tween:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(game_music_player, "volume_db", -25.0, fade_duration)

func stop_all_music(fade_duration: float = 1.0):
	if music_fade_tween:
		music_fade_tween.kill()
	
	var players_to_stop = []
	
	if menu_music_player and menu_music_player.playing:
		players_to_stop.append(menu_music_player)
	
	if game_music_player and game_music_player.playing:
		players_to_stop.append(game_music_player)
	
	if players_to_stop.size() == 0:
		current_music_type = ""
		return
	
	music_fade_tween = create_tween()
	music_fade_tween.set_parallel(true)
	
	for player in players_to_stop:
		music_fade_tween.tween_property(player, "volume_db", -60.0, fade_duration)
	
	await music_fade_tween.finished
	
	for player in players_to_stop:
		player.stop()
	
	current_music_type = ""

func stop_menu_music_for_game(fade_duration: float = 0.8):
	if current_music_type != "menu":
		return
	
	if music_fade_tween:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(menu_music_player, "volume_db", -60.0, fade_duration)
	
	await music_fade_tween.finished
	menu_music_player.stop()
	current_music_type = ""

func is_menu_music_playing() -> bool:
	return current_music_type == "menu" and menu_music_player and menu_music_player.playing

func is_game_music_playing() -> bool:
	return current_music_type == "game" and game_music_player and game_music_player.playing

func get_current_music_type() -> String:
	return current_music_type
