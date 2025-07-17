class_name AudioHelper
extends RefCounted

var audio_manager: AudioManager

func setup(manager: AudioManager):
	audio_manager = manager

func play_safe_audio(method_name: String, params: Array = []):
	if not audio_manager or not audio_manager.has_method(method_name):
		return
		
	match params.size():
		0:
			audio_manager.call(method_name)
		1:
			audio_manager.call(method_name, params[0])
		2:
			audio_manager.call(method_name, params[0], params[1])
		_:
			print("Demasiados parámetros para: ", method_name)

func play_card_play_sound(card_type: String = ""):
	play_safe_audio("play_card_play_sound", [card_type])

func play_card_draw_sound():
	play_safe_audio("play_card_draw_sound")

func play_card_hover_sound():
	play_safe_audio("play_card_hover_sound")

func play_turn_change_sound(is_player_turn: bool):
	play_safe_audio("play_turn_change_sound", [is_player_turn])

func play_win_sound():
	play_safe_audio("play_win_sound")

func play_lose_sound():
	play_safe_audio("play_lose_sound")

func play_deck_shuffle_sound():
	play_safe_audio("play_deck_shuffle_sound")

func play_notification_sound():
	play_safe_audio("play_notification_sound")

func play_bonus_sound():
	play_safe_audio("play_bonus_sound")

func play_damage_sound(damage: int):
	play_safe_audio("play_damage_sound", [damage])

func play_background_music():
	play_safe_audio("play_background_music")
