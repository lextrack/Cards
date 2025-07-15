class_name AudioManager
extends Node

# Card Sounds
@onready var card_play_player = $CardSounds/CardPlayPlayer
@onready var card_draw_player = $CardSounds/CardDrawPlayer
@onready var card_hover_player = $CardSounds/CardHoverPlayer

# Combat Sounds
@onready var attack_player = $CombatSounds/AttackPlayer
@onready var heal_player = $CombatSounds/HealPlayer
@onready var shield_player = $CombatSounds/ShieldPlayer
@onready var damage_player = $CombatSounds/DamagePlayer

# Game Sounds
@onready var turn_change_player = $GameSounds/TurnChangePlayer
@onready var win_player = $GameSounds/WinPlayer
@onready var lose_player = $GameSounds/LosePlayer
@onready var deck_shuffle_player = $GameSounds/DeckShufflePlayer
@onready var notification_player = $GameSounds/NotificationPlayer
@onready var bonus_player = $GameSounds/BonusPlayer
@onready var music_player: AudioStreamPlayer = $GameSounds/MusicPlayer

var original_volumes = {}

func _ready():
	save_original_volumes()
	play_background_music()

func save_original_volumes():
	original_volumes["music"] = music_player.volume_db
	original_volumes["card_play"] = card_play_player.volume_db
	original_volumes["card_draw"] = card_draw_player.volume_db
	original_volumes["card_hover"] = card_hover_player.volume_db
	original_volumes["attack"] = attack_player.volume_db
	original_volumes["heal"] = heal_player.volume_db
	original_volumes["shield"] = shield_player.volume_db
	original_volumes["damage"] = damage_player.volume_db
	original_volumes["turn_change"] = turn_change_player.volume_db
	original_volumes["win"] = win_player.volume_db
	original_volumes["lose"] = lose_player.volume_db
	original_volumes["deck_shuffle"] = deck_shuffle_player.volume_db
	original_volumes["notification"] = notification_player.volume_db
	original_volumes["bonus"] = bonus_player.volume_db
	
	#print("📊 Volúmenes originales guardados:", original_volumes)

func play_background_music():
	if music_player.stream:
		music_player.play()

func stop_music():
	music_player.stop()

func set_music_volume(volume_db: float):
	music_player.volume_db = original_volumes["music"] + volume_db

func set_sfx_volume(volume_offset: float):
	card_play_player.volume_db = original_volumes["card_play"] + volume_offset
	card_draw_player.volume_db = original_volumes["card_draw"] + volume_offset
	card_hover_player.volume_db = original_volumes["card_hover"] + volume_offset
	attack_player.volume_db = original_volumes["attack"] + volume_offset
	heal_player.volume_db = original_volumes["heal"] + volume_offset
	shield_player.volume_db = original_volumes["shield"] + volume_offset
	damage_player.volume_db = original_volumes["damage"] + volume_offset
	turn_change_player.volume_db = original_volumes["turn_change"] + volume_offset
	win_player.volume_db = original_volumes["win"] + volume_offset
	lose_player.volume_db = original_volumes["lose"] + volume_offset
	deck_shuffle_player.volume_db = original_volumes["deck_shuffle"] + volume_offset
	notification_player.volume_db = original_volumes["notification"] + volume_offset
	bonus_player.volume_db = original_volumes["bonus"] + volume_offset

func reset_volumes():
	music_player.volume_db = original_volumes["music"]
	card_play_player.volume_db = original_volumes["card_play"]
	card_draw_player.volume_db = original_volumes["card_draw"]
	card_hover_player.volume_db = original_volumes["card_hover"]
	attack_player.volume_db = original_volumes["attack"]
	heal_player.volume_db = original_volumes["heal"]
	shield_player.volume_db = original_volumes["shield"]
	damage_player.volume_db = original_volumes["damage"]
	turn_change_player.volume_db = original_volumes["turn_change"]
	win_player.volume_db = original_volumes["win"]
	lose_player.volume_db = original_volumes["lose"]
	deck_shuffle_player.volume_db = original_volumes["deck_shuffle"]
	notification_player.volume_db = original_volumes["notification"]
	bonus_player.volume_db = original_volumes["bonus"]

func play_card_play_sound(card_type: String = ""):
	match card_type:
		"attack":
			if attack_player.stream:
				attack_player.play()
		"heal":
			if heal_player.stream:
				heal_player.play()
		"shield":
			if shield_player.stream:
				shield_player.play()
		_:
			if card_play_player.stream:
				card_play_player.play()

func play_card_draw_sound():
	if card_draw_player.stream:
		card_draw_player.play()

func play_card_hover_sound():
	if card_hover_player.stream:
		card_hover_player.play()

func play_attack_sound(damage: int = 0):
	if attack_player.stream:
		var pitch = 1.0 + (damage * 0.05)
		attack_player.pitch_scale = clamp(pitch, 0.5, 2.0)
		attack_player.play()

func play_heal_sound():
	if heal_player.stream:
		heal_player.play()

func play_shield_sound():
	if shield_player.stream:
		shield_player.play()

func play_damage_sound(damage: int = 0):
	if damage_player.stream:
		var volume_bonus = min(damage * 0.5, 6.0)
		var original_volume = original_volumes["damage"]
		damage_player.volume_db = original_volume + volume_bonus
		damage_player.play()

		await damage_player.finished
		damage_player.volume_db = original_volume

func play_turn_change_sound(is_player_turn: bool):
	if turn_change_player.stream:
		turn_change_player.pitch_scale = 1.2 if is_player_turn else 0.8
		turn_change_player.play()

func play_win_sound():
	stop_music()
	if win_player.stream:
		win_player.play()

func play_lose_sound():
	stop_music()
	if lose_player.stream:
		lose_player.play()

func play_deck_shuffle_sound():
	if deck_shuffle_player.stream:
		deck_shuffle_player.play()

func play_notification_sound():
	if notification_player.stream:
		notification_player.play()

func play_bonus_sound():
	if bonus_player.stream:
		bonus_player.play()

func stop_all_sounds():
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
		for subchild in child.get_children():
			if subchild is AudioStreamPlayer:
				subchild.stop()

func is_music_playing() -> bool:
	return music_player.playing

func set_master_volume(volume_db: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

func get_current_volumes() -> Dictionary:
	var current = {}
	current["music"] = music_player.volume_db
	current["card_play"] = card_play_player.volume_db
	current["card_draw"] = card_draw_player.volume_db
	current["card_hover"] = card_hover_player.volume_db
	current["attack"] = attack_player.volume_db
	current["heal"] = heal_player.volume_db
	current["shield"] = shield_player.volume_db
	current["damage"] = damage_player.volume_db
	current["turn_change"] = turn_change_player.volume_db
	current["win"] = win_player.volume_db
	current["lose"] = lose_player.volume_db
	current["deck_shuffle"] = deck_shuffle_player.volume_db
	current["notification"] = notification_player.volume_db
	current["bonus"] = bonus_player.volume_db
	return current

func change_audio_stream(player_name: String, new_stream: AudioStream):
	var player = get_node_or_null(player_name)
	if player and player is AudioStreamPlayer:
		player.stream = new_stream
		print("🔄 Audio cambiado para: ", player_name)
