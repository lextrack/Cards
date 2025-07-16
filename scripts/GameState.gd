extends Node

var selected_difficulty: String = "normal"
var games_played: int = 0
var wins: int = 0
var losses: int = 0

func _ready():
	print("GameState inicializado")

func get_selected_difficulty() -> String:
	return selected_difficulty

func set_selected_difficulty(difficulty: String):
	selected_difficulty = difficulty

func add_game_result(player_won: bool):
	games_played += 1
	if player_won:
		wins += 1
	else:
		losses += 1

func get_win_rate() -> float:
	if games_played == 0:
		return 0.0
	return float(wins) / float(games_played)

func reset_stats():
	games_played = 0
	wins = 0
	losses = 0

func get_stats_text() -> String:
	if games_played == 0:
		return "Sin estadísticas aún"
	
	var win_rate = get_win_rate() * 100
	return "Partidas: %d | Victorias: %d | Derrotas: %d | Tasa: %.1f%%" % [games_played, wins, losses, win_rate]
