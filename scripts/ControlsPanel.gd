class_name ControlsPanel
extends Control

@onready var panel = $Panel
@onready var play_hint = $Panel/VBoxContainer/PlayHint
@onready var end_hint = $Panel/VBoxContainer/EndHint
@onready var restart_hint = $Panel/VBoxContainer/RestartHint
@onready var menu_hint = $Panel/VBoxContainer/MenuHint

@onready var play_icon = $Panel/VBoxContainer/PlayHint/PlayIcon
@onready var play_label = $Panel/VBoxContainer/PlayHint/PlayLabel
@onready var end_icon = $Panel/VBoxContainer/EndHint/EndIcon
@onready var end_label = $Panel/VBoxContainer/EndHint/EndLabel
@onready var restart_icon = $Panel/VBoxContainer/RestartHint/RestartIcon
@onready var restart_label = $Panel/VBoxContainer/RestartHint/RestartLabel
@onready var menu_icon = $Panel/VBoxContainer/MenuHint/MenuIcon
@onready var menu_label = $Panel/VBoxContainer/MenuHint/MenuLabel

var gamepad_mode: bool = false
var is_player_turn: bool = true
var has_cards: bool = false
var is_panel_hidden: bool = true
var toggle_tween: Tween

var xbox_a_texture = preload("res://assets/ui/buttons/xbox_a.png")
var xbox_b_texture = preload("res://assets/ui/buttons/xbox_b.png")
var xbox_x_texture = preload("res://assets/ui/buttons/xbox_x.png")
var xbox_y_texture = preload("res://assets/ui/buttons/xbox_y.png")
var key_esc_texture = preload("res://assets/ui/buttons/key_esc.png")
var key_r_texture = preload("res://assets/ui/buttons/key_r.png")
var mouse_click_texture = preload("res://assets/ui/buttons/mouse_click.png")

func _ready():
	setup_panel_style()
	visible = false

func setup_panel_style():
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   
	var panel_bg = $Panel/PanelBG
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.color = Color(0.08, 0.12, 0.18, 0.9)
   
	var style = StyleBoxFlat.new()
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.5, 0.6, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.bg_color = Color.TRANSPARENT
	panel.add_theme_stylebox_override("panel", style)
   
	var title = $Panel/VBoxContainer/Title
	title.text = "CONTROLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 1))
   
	var separator = $Panel/VBoxContainer/HSeparator
	separator.add_theme_color_override("separator", Color(0.3, 0.3, 0.4, 0.8))
   
	setup_icons()
	setup_labels()

func setup_icons():
	var icons = [play_icon, end_icon, restart_icon, menu_icon]
	for icon in icons:
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func setup_labels():
	var labels = [play_label, end_label, restart_label, menu_label]
	for label in labels:
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func update_gamepad_mode(new_gamepad_mode: bool):
	gamepad_mode = new_gamepad_mode
	update_display()

func update_player_turn(new_is_player_turn: bool):
	is_player_turn = new_is_player_turn
	update_display()

func update_cards_available(new_has_cards: bool):
	has_cards = new_has_cards
	update_display()

func update_display():
	if gamepad_mode:
		play_icon.texture = xbox_a_texture
		play_label.text = "Jugar carta"
   	
		end_icon.texture = xbox_b_texture
		end_label.text = "Terminar turno"
   	
		restart_icon.texture = xbox_x_texture
		restart_label.text = "Reiniciar"
   	
		menu_icon.texture = xbox_y_texture
		menu_label.text = "Menú"
	else:
		play_icon.texture = mouse_click_texture
		play_label.text = "Jugar carta"
   	
		end_icon.texture = mouse_click_texture
		end_label.text = "Terminar turno"
   	
		restart_icon.texture = key_r_texture
		restart_label.text = "Reiniciar"
   	
		menu_icon.texture = key_esc_texture
		menu_label.text = "Menú"
   
	play_hint.visible = is_player_turn and has_cards
	end_hint.visible = is_player_turn
	restart_hint.visible = true
	menu_hint.visible = true

func toggle_visibility():
	is_panel_hidden = !is_panel_hidden
	
	if toggle_tween:
		toggle_tween.kill()
	
	toggle_tween = create_tween()
	toggle_tween.set_parallel(true)
	
	if is_panel_hidden:
		toggle_tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
		toggle_tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.25).set_trans(Tween.TRANS_BACK)
		toggle_tween.tween_property(self, "rotation", deg_to_rad(-5), 0.2)
		await toggle_tween.finished
		visible = false
	else:
		visible = true
		modulate.a = 0.0
		scale = Vector2(0.7, 0.7)
		rotation = deg_to_rad(5)
		
		toggle_tween.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUINT)
		toggle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
		toggle_tween.tween_property(self, "rotation", deg_to_rad(0), 0.25)
		
		var bounce_tween = create_tween()
		bounce_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
		bounce_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func force_show():
	if toggle_tween:
		toggle_tween.kill()
   
	is_panel_hidden = false
	visible = true
	modulate.a = 1.0
	scale = Vector2(1.0, 1.0)

func force_hide():
	if toggle_tween:
		toggle_tween.kill()
   
	is_panel_hidden = false
	visible = false
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)

func show_with_animation():
	if not is_panel_hidden:
		visible = true
		modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_with_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	is_panel_hidden = false
