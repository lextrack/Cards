extends Node

var selected_difficulty: String = "normal"

func _ready():
	print("GameState initialized")
	

	if StatisticsManagers:
		StatisticsManagers.milestone_reached.connect(_on_milestone_reached)

func get_selected_difficulty() -> String:
	return selected_difficulty

func set_selected_difficulty(difficulty: String):
	selected_difficulty = difficulty

func add_game_result(player_won: bool):
	if StatisticsManagers:
		pass

func get_win_rate() -> float:
	if StatisticsManagers:
		return StatisticsManagers.get_win_rate()
	return 0.0

func reset_stats():
	if StatisticsManagers:
		StatisticsManagers.reset_statistics()

func get_stats_text() -> String:
	if not StatisticsManagers:
		return "Statistics not available"
	
	var stats = StatisticsManagers.get_comprehensive_stats()
	var basic = stats.basic
	
	if basic.games_played == 0:
		return "No statistics yet"
	
	return "Games: %d | Wins: %d | Losses: %d | Rate: %.1f%%" % [
		basic.games_played, 
		StatisticsManagers.games_won, 
		StatisticsManagers.games_lost, 
		basic.win_rate * 100.0
	]

# Revisar si de verdad lo voy a usar
func get_quick_stats() -> Dictionary:
	if not StatisticsManagers:
		return {"games_played": 0, "games_won": 0, "win_rate": 0.0}
	
	return {
		"games_played": StatisticsManagers.games_played,
		"games_won": StatisticsManagers.games_won,
		"games_lost": StatisticsManagers.games_lost,
		"win_rate": StatisticsManagers.get_win_rate(),
		"current_streak": StatisticsManagers.current_win_streak,
		"best_streak": StatisticsManagers.best_win_streak
	}

func _on_milestone_reached(milestone_type: String, value: int):
	match milestone_type:
		"games_played":
			print("🎉 Milestone reached: %d games played!" % value)
		"games_won":
			print("🏆 Milestone reached: %d games won!" % value)
		"win_streak":
			print("🔥 Milestone reached: %d win streak!" % value)
