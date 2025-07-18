class_name AudioManager
extends Node

signal audio_pool_exhausted(pool_name: String)
signal critical_audio_failed(audio_name: String)
signal audio_ducking_started(amount: float)
signal audio_ducking_stopped

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

var audio_pools: Dictionary = {}
var original_volumes: Dictionary = {}

var ducking_tween: Tween
var is_ducking: bool = false
var original_music_volume: float = 0.0

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var ui_volume: float = 1.0

func _ready():
	_save_original_volumes()
	_create_audio_pools_from_existing_nodes()
	play_background_music()
	print("🔊 AudioManager initialized using existing scene nodes")

func _save_original_volumes():
	original_volumes["card_play"] = card_play_player.volume_db
	original_volumes["card_draw"] = card_draw_player.volume_db
	original_volumes["card_hover"] = card_hover_player.volume_db if card_hover_player else -12.0
	original_volumes["attack"] = attack_player.volume_db
	original_volumes["heal"] = heal_player.volume_db
	original_volumes["shield"] = shield_player.volume_db
	original_volumes["damage"] = damage_player.volume_db
	original_volumes["turn_change"] = turn_change_player.volume_db if turn_change_player else -5.0
	original_volumes["win"] = win_player.volume_db
	original_volumes["lose"] = lose_player.volume_db
	original_volumes["deck_shuffle"] = deck_shuffle_player.volume_db if deck_shuffle_player else -2.0
	original_volumes["notification"] = notification_player.volume_db if notification_player else -5.0
	original_volumes["bonus"] = bonus_player.volume_db
	original_volumes["music"] = music_player.volume_db
	
	original_music_volume = music_player.volume_db

func _create_audio_pools_from_existing_nodes():
	_create_pool_from_node("card_play", card_play_player, 3, 6)
	_create_pool_from_node("card_draw", card_draw_player, 2, 4)
	_create_pool_from_node("card_hover", card_hover_player, 2, 4)
	
	_create_pool_from_node("attack", attack_player, 4, 8)
	_create_pool_from_node("heal", heal_player, 2, 4)
	_create_pool_from_node("shield", shield_player, 2, 4)
	_create_pool_from_node("damage", damage_player, 3, 6)
	
	_create_pool_from_node("turn_change", turn_change_player, 2, 4)
	_create_pool_from_node("win", win_player, 1, 2)
	_create_pool_from_node("lose", lose_player, 1, 2)
	_create_pool_from_node("deck_shuffle", deck_shuffle_player, 2, 3)
	_create_pool_from_node("notification", notification_player, 3, 5)
	_create_pool_from_node("bonus", bonus_player, 2, 4)

func _create_pool_from_node(pool_name: String, base_player: AudioStreamPlayer, initial_size: int = 3, max_size: int = 8):
	if not base_player:
		push_warning("AudioStreamPlayer node not found for pool: " + pool_name + " - skipping")
		return
		
	if not base_player.stream:
		push_warning("No stream assigned to AudioStreamPlayer for pool: " + pool_name + " - skipping")
		return
	
	var pool = AudioPool.new(pool_name, base_player.stream, initial_size, max_size)
	pool.original_volume_db = base_player.volume_db
	
	add_child(pool)
	audio_pools[pool_name] = pool
	
	pool.pool_exhausted.connect(_on_pool_exhausted)
	pool.audio_finished.connect(_on_audio_finished)
	
	if OS.is_debug_build():
		print("🔊 Created pool '%s' from existing node with %d players (vol: %.1f dB)" % [pool_name, initial_size, base_player.volume_db])

func play_audio(pool_name: String, request: AudioRequest = null) -> bool:
	if not audio_pools.has(pool_name):
		push_warning("Audio pool not found: " + pool_name + " - attempting fallback")
		
		var fallback_pool = _get_fallback_pool(pool_name)
		if fallback_pool != "" and audio_pools.has(fallback_pool):
			push_warning("Using fallback pool: " + fallback_pool + " for " + pool_name)
			return play_audio(fallback_pool, request)
		
		push_error("No fallback available for audio pool: " + pool_name)
		return false
	
	var pool = audio_pools[pool_name]

	if request and request.duck_other_audio:
		_start_ducking(request.duck_amount)
	
	if request:
		request.volume_offset += _get_category_volume_offset(request.category)
	
	if request and request.delay > 0.0:
		_play_audio_with_delay(pool, request)
		return true 
	
	var success = pool.play_audio(request)
	
	if not success:
		push_warning("Failed to play audio from pool: " + pool_name)
		if request and request.on_failed.is_valid():
			request.on_failed.call()
		
		if request and request.priority == AudioRequest.Priority.CRITICAL:
			critical_audio_failed.emit(pool_name)
	else:
		if request and request.on_started.is_valid():
			request.on_started.call()
	
	return success

func _get_fallback_pool(pool_name: String) -> String:
	"""Get a fallback pool for missing audio pools"""
	var fallbacks = {
		"card_hover": "card_play",
		"turn_change": "card_play", 
		"ui_click": "card_play",
		"ui_hover": "card_play",
		"notification": "card_play",
		"deck_shuffle": "card_draw",
		"bonus": "card_play",
		"win": "card_play",
		"lose": "card_play"
	}
	
	return fallbacks.get(pool_name, "")

func _play_audio_with_delay(pool: AudioPool, request: AudioRequest):
	"""Handle delayed audio playback asynchronously"""
	var delay = request.delay
	request.delay = 0.0 
	
	await get_tree().create_timer(delay).timeout
	pool.play_audio(request)

func play_card_play_sound(card_type: String = "", damage: int = 0) -> bool:
	match card_type:
		"attack":
			return play_attack_sound(damage)
		"heal":
			return play_heal_sound()
		"shield":
			return play_shield_sound()
		_:
			return play_audio("card_play")

func play_card_draw_sound() -> bool:
	return play_audio("card_draw")

func play_card_hover_sound() -> bool:
	var fallback_pools = ["card_hover", "notification", "card_play", "card_draw"]
	
	for pool_name in fallback_pools:
		if audio_pools.has(pool_name):
			var request = AudioRequest.create_ui_sound().with_volume(-8.0).with_pitch(1.05)
			return play_audio(pool_name, request)
	
	if OS.is_debug_build():
		push_warning("No audio pools available for hover sound")
	return false

func play_attack_sound(damage: int = 0) -> bool:
	var request = AudioRequest.create_attack_sound(damage)
	return play_audio("attack", request)

func play_heal_sound() -> bool:
	return play_audio("heal")

func play_shield_sound() -> bool:
	return play_audio("shield")

func play_damage_sound(damage: int = 0) -> bool:
	var request = AudioRequest.create_damage_sound(damage)
	return play_audio("damage", request)

func play_ui_click_sound() -> bool:
	var ui_pools = ["notification", "card_play"]
	
	for pool_name in ui_pools:
		if audio_pools.has(pool_name):
			var request = AudioRequest.create_ui_sound()
			return play_audio(pool_name, request)
	
	return false

func play_notification_sound() -> bool:
	var notify_pools = ["notification", "card_play"]
	
	for pool_name in notify_pools:
		if audio_pools.has(pool_name):
			var request = AudioRequest.create_ui_sound().with_pitch(1.2)
			return play_audio(pool_name, request)
	
	return false

func play_bonus_sound() -> bool:
	var bonus_pools = ["bonus", "notification", "card_play"]
	
	for pool_name in bonus_pools:
		if audio_pools.has(pool_name):
			var request = AudioRequest.create_critical_sound().with_pitch(1.3).with_volume(2.0)
			return play_audio(pool_name, request)
	
	return false

func play_turn_change_sound(is_player_turn: bool) -> bool:
	var pitch = 1.2 if is_player_turn else 0.8
	var request = AudioRequest.create_simple(pitch, 0.0)
	
	if audio_pools.has("turn_change"):
		return play_audio("turn_change", request)
	else:
		return play_audio("notification", request)

func play_win_sound() -> bool:
	stop_music()
	var request = AudioRequest.create_critical_sound().with_volume(5.0)
	return play_audio("win", request)

func play_lose_sound() -> bool:
	stop_music()
	var request = AudioRequest.create_critical_sound().with_volume(3.0)
	return play_audio("lose", request)

func play_deck_shuffle_sound() -> bool:
	var request = AudioRequest.create_simple(1.0, -2.0)
	
	if audio_pools.has("deck_shuffle"):
		return play_audio("deck_shuffle", request)
	else:
		return play_audio("card_draw", request)

func play_background_music():
	if music_player.stream:
		music_player.play()

func stop_music():
	music_player.stop()

func set_music_stream(stream: AudioStream):
	music_player.stream = stream

func fade_music_in(duration: float = 1.0):
	if not music_player.stream:
		return
	
	music_player.volume_db = -60.0
	music_player.play()
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", original_music_volume, duration)

func fade_music_out(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -60.0, duration)
	await tween.finished
	music_player.stop()
	music_player.volume_db = original_music_volume

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_changes()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_changes()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = original_volumes["music"] + linear_to_db(music_volume * master_volume)

func set_ui_volume(volume: float):
	ui_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_changes()

func _apply_volume_changes():
	for pool_name in audio_pools.keys():
		var pool = audio_pools[pool_name]
		var category_volume = _get_category_volume(pool_name)
		var volume_db = original_volumes[pool_name] + linear_to_db(category_volume * master_volume)
		pool.set_base_volume(volume_db)

func _get_category_volume(pool_name: String) -> float:
	if pool_name.begins_with("ui_"):
		return ui_volume
	else:
		return sfx_volume

func _get_category_volume_offset(category: AudioRequest.AudioCategory) -> float:
	match category:
		AudioRequest.AudioCategory.UI:
			return linear_to_db(ui_volume) - linear_to_db(sfx_volume)
		AudioRequest.AudioCategory.MUSIC:
			return linear_to_db(music_volume) - linear_to_db(sfx_volume)
		_:
			return 0.0

func _start_ducking(duck_amount: float):
	if is_ducking:
		return
	
	is_ducking = true
	audio_ducking_started.emit(duck_amount)
	
	if ducking_tween:
		ducking_tween.kill()
	
	ducking_tween = create_tween()
	ducking_tween.tween_property(music_player, "volume_db", original_music_volume + duck_amount, 0.2)

func _stop_ducking():
	if not is_ducking:
		return
	
	is_ducking = false
	audio_ducking_stopped.emit()
	
	if ducking_tween:
		ducking_tween.kill()
	
	ducking_tween = create_tween()
	ducking_tween.tween_property(music_player, "volume_db", original_music_volume, 0.5)

func play_simultaneous_sounds(pool_names: Array, requests: Array = []) -> bool:
	var success_count = 0
	
	for i in range(pool_names.size()):
		var pool_name = pool_names[i]
		var request = requests[i] if i < requests.size() else null
		
		if play_audio(pool_name, request):
			success_count += 1
	
	return success_count > 0

func play_layered_sounds(base_pool: String, layer_pools: Array, volume_reduction: float = -3.0) -> bool:
	var base_success = play_audio(base_pool)
	
	for layer_pool in layer_pools:
		var request = AudioRequest.create_layered_sound(volume_reduction)
		play_audio(layer_pool, request)
	
	return base_success

func stop_all_sounds():
	for pool in audio_pools.values():
		pool.stop_all()
	
	if is_ducking:
		_stop_ducking()

func is_any_audio_playing() -> bool:
	for pool in audio_pools.values():
		if pool.is_any_playing():
			return true
	return music_player.playing
	
func _on_pool_exhausted(pool_name: String):
	audio_pool_exhausted.emit(pool_name)
	
	var pool = audio_pools[pool_name]
	if pool.force_expand_pool():
		if OS.is_debug_build():
			print("🔊 Auto-expanded pool: ", pool_name)

func _on_audio_finished(pool_name: String, player_index: int):
	if is_ducking and not _is_any_sfx_playing():
		_stop_ducking()

func _is_any_sfx_playing() -> bool:
	for pool_name in audio_pools.keys():
		if not pool_name.begins_with("music_"):
			var pool = audio_pools[pool_name]
			if pool.is_any_playing():
				return true
	return false

func debug_print_pools():
	if OS.is_debug_build():
		print("\n🔊 === AUDIO POOLS STATUS ===")
		for pool in audio_pools.values():
			pool.debug_print_status()
		print("Music playing: ", music_player.playing)
		print("Is ducking: ", is_ducking)
		print("==============================\n")

func get_audio_statistics() -> Dictionary:
	var stats = {
		"total_pools": audio_pools.size(),
		"music_playing": music_player.playing,
		"is_ducking": is_ducking,
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"ui_volume": ui_volume,
		"pools": {}
	}
	
	for pool_name in audio_pools.keys():
		stats.pools[pool_name] = audio_pools[pool_name].get_pool_info()
	
	return stats
