extends Control

@onready var normal_card = $MenuContainer/DifficultyContainer/NormalContainer/NormalCard
@onready var hard_card = $MenuContainer/DifficultyContainer/HardContainer/HardCard
@onready var expert_card = $MenuContainer/DifficultyContainer/ExpertContainer/ExpertCard

@onready var normal_bg = $MenuContainer/DifficultyContainer/NormalContainer/NormalCard/NormalCardBG
@onready var hard_bg = $MenuContainer/DifficultyContainer/HardContainer/HardCard/HardCardBG
@onready var expert_bg = $MenuContainer/DifficultyContainer/ExpertContainer/ExpertCard/ExpertCardBG

@onready var back_button = $MenuContainer/ButtonsContainer/BackButton
@onready var start_button = $MenuContainer/ButtonsContainer/StartButton

@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

var selected_difficulty: String = "normal"
var is_transitioning: bool = false

var normal_colors = {
	"selected": Color(0.2, 0.35, 0.5, 1.0),
	"normal": Color(0.15, 0.2, 0.3, 0.9),
	"hover": Color(0.18, 0.25, 0.35, 0.95)
}

var hard_colors = {
	"selected": Color(0.4, 0.25, 0.15, 1.0),
	"normal": Color(0.25, 0.15, 0.1, 0.9),
	"hover": Color(0.3, 0.18, 0.12, 0.95)
}

var expert_colors = {
	"selected": Color(0.45, 0.15, 0.15, 1.0),
	"normal": Color(0.3, 0.1, 0.1, 0.9),
	"hover": Color(0.35, 0.12, 0.12, 0.95)
}

func _ready():
	setup_cards()
	setup_buttons()
	
	await handle_scene_entrance()

	select_difficulty("normal")

	normal_card.grab_focus()

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and 
			TransitionManager.current_overlay.is_ready() and 
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):
			
			await TransitionManager.current_overlay.fade_out(0.1)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)

	await tween.finished
	animate_cards_entrance()

func animate_cards_entrance():
	normal_card.position.y -= 50
	hard_card.position.y -= 50
	expert_card.position.y -= 50
	normal_card.modulate.a = 0.0
	hard_card.modulate.a = 0.0
	expert_card.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(normal_card, "position:y", normal_card.position.y + 50, 0.4)
	tween.tween_property(normal_card, "modulate:a", 1.0, 0.4)

	await get_tree().create_timer(0.15).timeout
	tween.tween_property(hard_card, "position:y", hard_card.position.y + 50, 0.4)
	tween.tween_property(hard_card, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.15).timeout
	tween.tween_property(expert_card, "position:y", expert_card.position.y + 50, 0.4)
	tween.tween_property(expert_card, "modulate:a", 1.0, 0.4)

func setup_cards():
	normal_card.focus_mode = Control.FOCUS_ALL
	hard_card.focus_mode = Control.FOCUS_ALL
	expert_card.focus_mode = Control.FOCUS_ALL
	
	normal_card.focus_neighbor_right = hard_card.get_path()
	hard_card.focus_neighbor_left = normal_card.get_path()
	hard_card.focus_neighbor_right = expert_card.get_path()
	expert_card.focus_neighbor_left = hard_card.get_path()
	
	normal_card.focus_neighbor_bottom = start_button.get_path()
	hard_card.focus_neighbor_bottom = start_button.get_path()
	expert_card.focus_neighbor_bottom = start_button.get_path()
	
	normal_card.gui_input.connect(_on_card_input.bind("normal"))
	hard_card.gui_input.connect(_on_card_input.bind("hard"))
	expert_card.gui_input.connect(_on_card_input.bind("expert"))
	
	normal_card.mouse_entered.connect(_on_card_hover.bind("normal"))
	normal_card.mouse_exited.connect(_on_card_unhover.bind("normal"))
	hard_card.mouse_entered.connect(_on_card_hover.bind("hard"))
	hard_card.mouse_exited.connect(_on_card_unhover.bind("hard"))
	expert_card.mouse_entered.connect(_on_card_hover.bind("expert"))
	expert_card.mouse_exited.connect(_on_card_unhover.bind("expert"))
	
	normal_card.focus_entered.connect(_on_card_focus.bind("normal"))
	hard_card.focus_entered.connect(_on_card_focus.bind("hard"))
	expert_card.focus_entered.connect(_on_card_focus.bind("expert"))

func setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	back_button.focus_neighbor_right = start_button.get_path()
	start_button.focus_neighbor_left = back_button.get_path()

	back_button.focus_neighbor_top = normal_card.get_path()
	start_button.focus_neighbor_top = hard_card.get_path()

	var all_buttons = [back_button, start_button]
	
	for button in all_buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.focus_entered.connect(_on_button_focus.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.focus_exited.connect(_on_button_unfocus.bind(button))

func _on_card_input(event: InputEvent, difficulty: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_difficulty_selected(difficulty)

func _on_card_hover(difficulty: String):
	if selected_difficulty == difficulty:
		return
		
	play_hover_sound()
	
	var card_bg = get_card_bg(difficulty)
	var colors = get_colors(difficulty)
	
	if card_bg:
		var tween = create_tween()
		tween.tween_property(card_bg, "color", colors.hover, 0.2)

func _on_card_unhover(difficulty: String):
	if selected_difficulty == difficulty:
		return
		
	var card_bg = get_card_bg(difficulty)
	var colors = get_colors(difficulty)
	
	if card_bg:
		var tween = create_tween()
		tween.tween_property(card_bg, "color", colors.normal, 0.2)

func _on_card_focus(difficulty: String):
	play_hover_sound()
	select_difficulty(difficulty)

func get_card_bg(difficulty: String) -> ColorRect:
	match difficulty:
		"normal":
			return normal_bg
		"hard":
			return hard_bg
		"expert":
			return expert_bg
		_:
			return null

func get_colors(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return normal_colors
		"hard":
			return hard_colors
		"expert":
			return expert_colors
		_:
			return normal_colors

func _on_difficulty_selected(difficulty: String):
	if is_transitioning:
		return
	
	select_difficulty(difficulty)

func select_difficulty(difficulty: String):
	if selected_difficulty == difficulty:
		return
		
	selected_difficulty = difficulty
	play_ui_sound("select")
	
	update_card_colors("normal")
	update_card_colors("hard")
	update_card_colors("expert")
	
	animate_selected_card(difficulty)
	
	update_start_button_text()

func update_card_colors(difficulty: String):
	var card_bg = get_card_bg(difficulty)
	var colors = get_colors(difficulty)
	
	if not card_bg:
		return
	
	var target_color = colors.selected if selected_difficulty == difficulty else colors.normal
	
	var tween = create_tween()
	tween.tween_property(card_bg, "color", target_color, 0.3)

func animate_selected_card(difficulty: String):
	var card = get_card_node(difficulty)
	
	if card:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.15)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)

func get_card_node(difficulty: String) -> Control:
	match difficulty:
		"normal":
			return normal_card
		"hard":
			return hard_card
		"expert":
			return expert_card
		_:
			return null

func update_start_button_text():
	var difficulty_name = selected_difficulty.to_upper()
	start_button.text = "🎮 JUGAR " + difficulty_name

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 1.0)

func _on_start_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	GameState.selected_difficulty = selected_difficulty
	
	TransitionManager.fade_to_scene("res://scenes/Main.tscn", 1.2)

func _on_button_hover(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unfocus(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func play_ui_sound(sound_type: String):
	match sound_type:
		"button_click", "select":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
			pass
		_:
			pass

func play_hover_sound():
	pass

func _input(event):
	if is_transitioning:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
	elif event.is_action_pressed("ui_accept"):
		if normal_card.has_focus() or hard_card.has_focus() or expert_card.has_focus():
			_on_start_pressed()
		elif start_button.has_focus():
			_on_start_pressed()
		elif back_button.has_focus():
			_on_back_pressed()
	
	elif event.is_action_pressed("gamepad_accept"):
		if normal_card.has_focus() or hard_card.has_focus() or expert_card.has_focus():
			_on_start_pressed()
		elif start_button.has_focus():
			_on_start_pressed()
		elif back_button.has_focus():
			_on_back_pressed()
	
	elif event.is_action_pressed("gamepad_cancel"):
		_on_back_pressed()
