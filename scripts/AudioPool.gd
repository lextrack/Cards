class_name AudioPool
extends Node

signal audio_finished(pool_name: String, player_index: int)
signal pool_exhausted(pool_name: String)

var pool_name: String
var audio_stream: AudioStream
var players: Array[AudioStreamPlayer] = []
var available_players: Array[int] = []
var busy_players: Array[int] = []
var max_pool_size: int = 8
var original_volume_db: float = 0.0

func _init(name: String, stream: AudioStream, initial_size: int = 3, max_size: int = 8):
	pool_name = name
	audio_stream = stream
	max_pool_size = max_size
	_create_initial_pool(initial_size)

func _ready():
	name = "AudioPool_" + pool_name

func _create_initial_pool(size: int):
	for i in range(size):
		_create_new_player()

func _create_new_player() -> int:
	if players.size() >= max_pool_size:
		return -1
	
	var player = AudioStreamPlayer.new()
	player.stream = audio_stream
	player.volume_db = original_volume_db
	
	player.finished.connect(_on_player_finished.bind(players.size()))
	
	add_child(player)
	players.append(player)
	available_players.append(players.size() - 1)
	
	return players.size() - 1

func _on_player_finished(player_index: int):
	if player_index in busy_players:
		busy_players.erase(player_index)
		available_players.append(player_index)
		
		var player = players[player_index]
		player.pitch_scale = 1.0
		player.volume_db = original_volume_db
		
		audio_finished.emit(pool_name, player_index)

func play_audio(request: AudioRequest = null) -> bool:
	var player_index = _get_available_player()
	
	if player_index == -1:
		pool_exhausted.emit(pool_name)
		return false
	
	var player = players[player_index]

	if request:
		player.pitch_scale = request.pitch
		player.volume_db = original_volume_db + request.volume_offset
	else:
		player.pitch_scale = 1.0
		player.volume_db = original_volume_db
	
	player.play()
	
	available_players.erase(player_index)
	busy_players.append(player_index)
	
	return true

func _get_available_player() -> int:
	if available_players.size() > 0:
		return available_players[0]
	
	if players.size() < max_pool_size:
		return _create_new_player()
	
	return -1

func stop_all():
	for i in range(players.size()):
		if players[i].playing:
			players[i].stop()
		_on_player_finished(i)

func set_base_volume(volume_db: float):
	original_volume_db = volume_db
	
	for i in available_players:
		players[i].volume_db = volume_db

func is_any_playing() -> bool:
	return busy_players.size() > 0

func get_pool_info() -> Dictionary:
	return {
		"name": pool_name,
		"total_players": players.size(),
		"available": available_players.size(),
		"busy": busy_players.size(),
		"max_size": max_pool_size,
		"stream": audio_stream.resource_path if audio_stream else "none"
	}

func force_expand_pool() -> bool:
	if players.size() < max_pool_size:
		_create_new_player()
		return true
	return false
