class_name AudioHelper
extends RefCounted

var audio_manager: AudioManager
var is_initialized: bool = false

func setup(manager: AudioManager):
	audio_manager = manager
	is_initialized = audio_manager != null

func play_card_play_sound(card_type: String = "", damage: int = 0) -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_card_play_sound(card_type, damage)

func play_card_draw_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_card_draw_sound()

func play_card_hover_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_card_hover_sound()

func play_attack_sound(damage: int = 0) -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_attack_sound(damage)

func play_heal_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_heal_sound()

func play_shield_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_shield_sound()

func play_damage_sound(damage: int = 0) -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_damage_sound(damage)

func play_ui_click_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_ui_click_sound()

func play_notification_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_notification_sound()

func play_bonus_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_bonus_sound()

func play_turn_change_sound(is_player_turn: bool) -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_turn_change_sound(is_player_turn)

func play_win_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_win_sound()

func play_lose_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_lose_sound()

func play_deck_shuffle_sound() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_deck_shuffle_sound()

func play_background_music() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_background_music()

func stop_background_music() -> bool:
	if not is_initialized:
		return false
	return audio_manager.stop_music()

func fade_music_out(duration: float = 1.0):
	if is_initialized:
		audio_manager.fade_music_out(duration)

func fade_music_in(duration: float = 1.0):
	if is_initialized:
		audio_manager.fade_music_in(duration)

func stop_all_audio():
	if is_initialized:
		audio_manager.stop_all_sounds()

func is_any_audio_playing() -> bool:
	if not is_initialized:
		return false
	return audio_manager.is_any_audio_playing()
