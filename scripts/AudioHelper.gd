class_name AudioHelper
extends RefCounted

var audio_manager: AudioManager
var is_initialized: bool = false

signal audio_system_error(error_message: String)
signal audio_played_successfully(pool_name: String)

func setup(manager: AudioManager):
	audio_manager = manager
	is_initialized = _validate_audio_manager()
	
	if is_initialized:
		print("🔊 AudioHelper initialized successfully")
	else:
		push_error("AudioHelper failed to initialize - AudioManager validation failed")

func _validate_audio_manager() -> bool:
	if not audio_manager:
		return false
	
	if not audio_manager.has_method("play_audio"):
		push_error("AudioManager missing required method: play_audio")
		return false
	
	return true

func play_safe_audio(method_name: String, params: Array = []) -> bool:
	if not _check_audio_system():
		return false
	
	if not audio_manager.has_method(method_name):
		_handle_error("Method not found: " + method_name)
		return false
	
	var success = false
	
	match params.size():
		0:
			success = audio_manager.call(method_name)
		1:
			success = audio_manager.call(method_name, params[0])
		2:
			success = audio_manager.call(method_name, params[0], params[1])
		3:
			success = audio_manager.call(method_name, params[0], params[1], params[2])
		_:
			_handle_error("Too many parameters for method: " + method_name)
			return false
	
	if success:
		audio_played_successfully.emit(method_name)
	
	return success

func _check_audio_system() -> bool:
	if not is_initialized:
		_handle_error("AudioHelper not properly initialized")
		return false
	
	if not is_instance_valid(audio_manager):
		_handle_error("AudioManager instance is invalid")
		is_initialized = false
		return false
	
	return true

func _handle_error(message: String):
	push_warning("AudioHelper: " + message)
	audio_system_error.emit(message)

func play_card_play_sound(card_type: String = "", damage: int = 0) -> bool:
	if not _check_audio_system():
		return false
	
	return audio_manager.play_card_play_sound(card_type, damage)

func play_card_draw_sound() -> bool:
	return play_safe_audio("play_card_draw_sound")

func play_card_hover_sound() -> bool:
	return play_safe_audio("play_card_hover_sound")

func play_attack_sound(damage: int = 0) -> bool:
	if not _check_audio_system():
		return false
	
	return audio_manager.play_attack_sound(damage)

func play_heal_sound() -> bool:
	return play_safe_audio("play_heal_sound")

func play_shield_sound() -> bool:
	return play_safe_audio("play_shield_sound")

func play_damage_sound(damage: int = 0) -> bool:
	if not _check_audio_system():
		return false
	
	return audio_manager.play_damage_sound(damage)

func play_ui_click_sound() -> bool:
	return play_safe_audio("play_ui_click_sound")

func play_notification_sound() -> bool:
	return play_safe_audio("play_notification_sound")

func play_bonus_sound() -> bool:
	return play_safe_audio("play_bonus_sound")

func play_turn_change_sound(is_player_turn: bool) -> bool:
	if not _check_audio_system():
		return false
	
	return audio_manager.play_turn_change_sound(is_player_turn)

func play_win_sound() -> bool:
	return play_safe_audio("play_win_sound")

func play_lose_sound() -> bool:
	return play_safe_audio("play_lose_sound")

func play_deck_shuffle_sound() -> bool:
	return play_safe_audio("play_deck_shuffle_sound")

func play_background_music() -> bool:
	return play_safe_audio("play_background_music")

func stop_background_music() -> bool:
	return play_safe_audio("stop_music")

func fade_music_in(duration: float = 1.0) -> bool:
	if not _check_audio_system():
		return false
	
	audio_manager.fade_music_in(duration)
	return true

func fade_music_out(duration: float = 1.0) -> bool:
	if not _check_audio_system():
		return false
	
	audio_manager.fade_music_out(duration)
	return true

func play_simultaneous_card_sounds(card_types: Array) -> bool:
	"""Play multiple card sounds at the same time"""
	if not _check_audio_system():
		return false
	
	var pool_names = []
	var requests = []
	
	for card_type in card_types:
		match card_type:
			"attack":
				pool_names.append("attack")
				requests.append(AudioRequest.create_simple())
			"heal":
				pool_names.append("heal")
				requests.append(AudioRequest.create_simple())
			"shield":
				pool_names.append("shield")
				requests.append(AudioRequest.create_simple())
			_:
				pool_names.append("card_play")
				requests.append(AudioRequest.create_simple())
	
	return audio_manager.play_simultaneous_sounds(pool_names, requests)

func play_combo_attack_sound(damage: int, combo_multiplier: int = 1) -> bool:
	"""Play layered attack sounds for combo effects"""
	if not _check_audio_system():
		return false
	
	var base_request = AudioRequest.create_attack_sound(damage)
	var base_success = audio_manager.play_audio("attack", base_request)
	
	for i in range(combo_multiplier - 1):
		var layer_request = AudioRequest.create_layered_sound(-6.0).with_delay(0.1 * (i + 1))
		audio_manager.play_audio("attack", layer_request)
	
	return base_success

func play_critical_hit_sound(damage: int) -> bool:
	"""Play special sound for critical hits"""
	if not _check_audio_system():
		return false
	
	var base_pools = ["attack", "ui_click"]
	var requests = [
		AudioRequest.create_attack_sound(damage).with_volume(3.0),
		AudioRequest.create_critical_sound().with_pitch(1.5).with_delay(0.1)
	]
	
	return audio_manager.play_simultaneous_sounds(base_pools, requests)

func play_card_sequence_sound(cards_count: int, interval: float = 0.2) -> bool:
	"""Play card sounds in sequence (for drawing multiple cards)"""
	if not _check_audio_system():
		return false
	
	var success = false
	for i in range(cards_count):
		var request = AudioRequest.create_simple().with_delay(i * interval).with_pitch(1.0 + i * 0.1)
		var result = audio_manager.play_audio("card_draw", request)
		if i == 0: 
			success = result
	
	return success

func set_master_volume(volume: float) -> bool:
	if not _check_audio_system():
		return false
	
	audio_manager.set_master_volume(volume)
	return true

func set_sfx_volume(volume: float) -> bool:
	if not _check_audio_system():
		return false
	
	audio_manager.set_sfx_volume(volume)
	return true

func set_music_volume(volume: float) -> bool:
	if not _check_audio_system():
		return false
	
	audio_manager.set_music_volume(volume)
	return true

func set_ui_volume(volume: float) -> bool:
	if not _check_audio_system():
		return false
	
	audio_manager.set_ui_volume(volume)
	return true

func is_any_audio_playing() -> bool:
	if not _check_audio_system():
		return false
	
	return audio_manager.is_any_audio_playing()

func is_music_playing() -> bool:
	if not _check_audio_system():
		return false
	
	return audio_manager.music_player.playing

func get_audio_statistics() -> Dictionary:
	if not _check_audio_system():
		return {}
	
	return audio_manager.get_audio_statistics()

func stop_all_audio() -> bool:
	if not _check_audio_system():
		return false
	
	audio_manager.stop_all_sounds()
	return true

func emergency_silence() -> bool:
	"""Complete audio silence - for critical situations"""
	if not _check_audio_system():
		return false
	
	audio_manager.stop_all_sounds()
	audio_manager.stop_music()
	audio_manager.set_master_volume(0.0)
	return true

func restore_audio() -> bool:
	"""Restore audio after emergency silence"""
	if not _check_audio_system():
		return false
	
	audio_manager.set_master_volume(1.0)
	audio_manager.play_background_music()
	return true

func play_turn_start_sequence(is_player: bool, turn_number: int) -> bool:
	"""Play appropriate sounds for turn start"""
	if not _check_audio_system():
		return false
	
	play_turn_change_sound(is_player)
	
	var draw_request = AudioRequest.create_simple().with_delay(0.3)
	audio_manager.play_audio("card_draw", draw_request)
	
	if turn_number % 5 == 0 and turn_number > 5:
		var special_request = AudioRequest.create_ui_sound().with_pitch(1.3).with_delay(0.6)
		audio_manager.play_audio("ui_click", special_request)
	
	return true

func play_game_over_sequence(player_won: bool) -> bool:
	"""Play comprehensive game over audio sequence"""
	if not _check_audio_system():
		return false
	
	if player_won:
		play_win_sound()
		var fanfare_request = AudioRequest.create_critical_sound().with_delay(0.5).with_pitch(1.2)
		audio_manager.play_audio("ui_click", fanfare_request)
	else:
		play_lose_sound()
		var defeat_request = AudioRequest.create_simple().with_delay(0.4).with_pitch(0.7)
		audio_manager.play_audio("ui_click", defeat_request)
	
	return true

func play_card_effect_audio(card_type: String, effect_value: int, is_critical: bool = false) -> bool:
	"""Play contextual audio based on card effect"""
	if not _check_audio_system():
		return false
	
	if is_critical:
		return play_critical_hit_sound(effect_value)
	else:
		return play_card_play_sound(card_type, effect_value)

func play_ui_feedback(action: String, success: bool = true) -> bool:
	"""Play standardized UI feedback sounds"""
	if not _check_audio_system():
		return false
	
	var request: AudioRequest
	
	match action:
		"select":
			request = AudioRequest.create_ui_sound().with_pitch(1.1)
		"confirm":
			request = AudioRequest.create_ui_sound().with_pitch(1.3) if success else AudioRequest.create_ui_sound().with_pitch(0.8)
		"cancel":
			request = AudioRequest.create_ui_sound().with_pitch(0.9)
		"error":
			request = AudioRequest.create_ui_sound().with_pitch(0.7).with_volume(-3.0)
		"navigation":
			request = AudioRequest.create_ui_sound().with_pitch(1.05).with_volume(-8.0)
		_:
			request = AudioRequest.create_ui_sound()
	
	return audio_manager.play_audio("ui_click", request)

func _wait_for_audio(duration: float):
	"""Helper for audio testing"""
	if audio_manager and audio_manager.get_tree():
		await audio_manager.get_tree().create_timer(duration).timeout

func reinitialize() -> bool:
	"""Reinitialize the audio helper"""
	if audio_manager:
		return setup(audio_manager)
	return false

func is_ready() -> bool:
	"""Check if audio system is ready"""
	return is_initialized and _check_audio_system()

func quick_play(sound_name: String, pitch: float = 1.0, volume: float = 0.0, delay: float = 0.0) -> bool:
	"""Quick way to play common sounds with basic parameters"""
	if not _check_audio_system():
		return false
	
	var pool_name = _get_pool_name_for_sound(sound_name)
	if pool_name.is_empty():
		_handle_error("Unknown sound name: " + sound_name)
		return false
	
	var request = AudioRequest.create_simple(pitch, volume).with_delay(delay)
	return audio_manager.play_audio(pool_name, request)

func _get_pool_name_for_sound(sound_name: String) -> String:
	"""Map friendly sound names to pool names"""
	var sound_map = {
		"card": "card_play",
		"draw": "card_draw",
		"attack": "attack",
		"heal": "heal",
		"shield": "shield",
		"damage": "damage",
		"click": "ui_click",
		"hover": "ui_hover",
		"button": "ui_click",
		"notification": "ui_click"
	}
	
	return sound_map.get(sound_name, "")
