class_name AudioManager
extends Node

@onready var card_play_player = $CardSounds/CardPlayPlayer
@onready var card_draw_player = $CardSounds/CardDrawPlayer
@onready var card_hover_player = $CardSounds/CardHoverPlayer

@onready var attack_player = $CombatSounds/AttackPlayer
@onready var heal_player = $CombatSounds/HealPlayer
@onready var shield_player = $CombatSounds/ShieldPlayer
@onready var damage_player = $CombatSounds/DamagePlayer

@onready var turn_change_player = $GameSounds/TurnChangePlayer
@onready var win_player = $GameSounds/WinPlayer
@onready var lose_player = $GameSounds/LosePlayer
@onready var deck_shuffle_player = $GameSounds/DeckShufflePlayer
@onready var notification_player = $GameSounds/NotificationPlayer
@onready var bonus_player = $GameSounds/BonusPlayer
@onready var music_player = $GameSounds/MusicPlayer

var player_pools: Dictionary = {}

func _ready():
	_create_player_pools()

func _create_player_pools():
	_create_pool("card_play", card_play_player, 3)
	_create_pool("card_draw", card_draw_player, 3)
	_create_pool("card_hover", card_hover_player, 2)
	_create_pool("attack", attack_player, 5)
	_create_pool("heal", heal_player, 3)
	_create_pool("shield", shield_player, 3)
	_create_pool("damage", damage_player, 4)
	_create_pool("turn_change", turn_change_player, 2)
	_create_pool("win", win_player, 1)
	_create_pool("lose", lose_player, 1)
	_create_pool("deck_shuffle", deck_shuffle_player, 2)
	_create_pool("notification", notification_player, 4)
	_create_pool("bonus", bonus_player, 2)

func _create_pool(pool_name: String, base_player: AudioStreamPlayer, pool_size: int):
	if not base_player or not base_player.stream:
		return
	
	var pool = []
	for i in range(pool_size):
		var player = AudioStreamPlayer.new()
		player.stream = base_player.stream
		player.volume_db = base_player.volume_db
		player.pitch_scale = base_player.pitch_scale
		player.bus = base_player.bus
		add_child(player)
		pool.append(player)
	
	player_pools[pool_name] = pool

func _get_available_player(pool_name: String) -> AudioStreamPlayer:
	if not player_pools.has(pool_name):
		return null
	
	var pool = player_pools[pool_name]
	for player in pool:
		if not player.playing:
			return player
	
	return pool[0]

func play_card_play_sound(card_type: String = "", damage: int = 0) -> bool:
	match card_type:
		"attack":
			return play_attack_sound()
		"heal":
			return play_heal_sound()
		"shield":
			return play_shield_sound()
		_:
			return _play_sound("card_play")

func play_card_draw_sound() -> bool:
	return _play_sound("card_draw")

func play_card_hover_sound() -> bool:
	return _play_sound("card_hover")

func play_attack_sound(damage: int = 0) -> bool:
	return _play_sound("attack")

func play_heal_sound() -> bool:
	return _play_sound("heal")

func play_shield_sound() -> bool:
	return _play_sound("shield")

func play_damage_sound(damage: int = 0) -> bool:
	return _play_sound("damage")

func play_ui_click_sound() -> bool:
	return _play_sound("notification")

func play_notification_sound() -> bool:
	return _play_sound("notification")

func play_bonus_sound() -> bool:
	return _play_sound("bonus")

func play_turn_change_sound(is_player_turn: bool) -> bool:
	return _play_sound("turn_change")

func play_win_sound() -> bool:
	stop_music()
	return _play_sound("win")

func play_lose_sound() -> bool:
	stop_music()
	return _play_sound("lose")

func play_deck_shuffle_sound() -> bool:
	return _play_sound("deck_shuffle")

func _play_sound(sound_name: String) -> bool:
	var player = _get_available_player(sound_name)
	if player:
		player.play()
		return true
	return false

func play_background_music() -> bool:
	if music_player and music_player.stream:
		music_player.play()
		return true
	return false

func stop_music() -> bool:
	if music_player:
		music_player.stop()
		return true
	return false

func fade_music_out(duration: float = 1.0):
	if not music_player:
		return
	
	var original_volume = music_player.volume_db
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -60.0, duration)
	await tween.finished
	music_player.stop()
	music_player.volume_db = original_volume

func fade_music_in(duration: float = 1.0):
	if not music_player or not music_player.stream:
		return
	
	var target_volume = music_player.volume_db
	music_player.volume_db = -60.0
	music_player.play()
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", target_volume, duration)

func stop_all_sounds():
	for pool_name in player_pools.keys():
		var pool = player_pools[pool_name]
		for player in pool:
			if player.playing:
				player.stop()

func is_any_audio_playing() -> bool:
	for pool_name in player_pools.keys():
		var pool = player_pools[pool_name]
		for player in pool:
			if player.playing:
				return true
	return music_player.playing if music_player else false
