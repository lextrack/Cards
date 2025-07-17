extends Control

@onready var topics_buttons_container = $MainContainer/ContentContainer/TopicsPanel/TopicsContainer/TopicsButtonsContainer
@onready var content_label = $MainContainer/ContentContainer/ContentPanel/ContentScrollContainer/ContentLabel
@onready var back_button = $MainContainer/ButtonsContainer/BackButton
@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

var is_transitioning: bool = false
var selected_topic_button: Button = null

var help_topics = {
	"📖 Basic Rules": """[font_size=24][color=yellow]⚔️ GAME RULES[/color][/font_size]

[font_size=18][color=lightblue]🎯 OBJECTIVE:[/color][/font_size]
Reduce your opponent's health to 0 to win the match.

[font_size=18][color=lightblue]🎮 TURNS:[/color][/font_size]
• Each turn you receive full mana and draw cards
• You can play cards by paying their mana cost
• You have a card limit per turn (based on difficulty)
• When you end your turn, the opponent plays

[font_size=18][color=lightblue]💎 RESOURCES:[/color][/font_size]
• [color=red]HEALTH[/color]: If it reaches 0, you lose the match
• [color=cyan]MANA[/color]: Used to play cards, regenerates each turn
• [color=orange]CARDS[/color]: Your arsenal: depending on difficulty, you can use up to 4 or 5 cards per turn. Special cards shine brighter
• [color=white]DECKS[/color]: Available card count (automatically replenished, you'll never run out)""",

	"🃏 Card Types": """[font_size=24][color=yellow]🗂️ CARD TYPES[/color][/font_size]

[font_size=18][color=red]⚔️ ATTACK CARDS:[/color][/font_size]
• Deal direct damage to the opponent
• First affects shield, then health
• Examples: Basic Strike (1 damage), Sharp Sword (5 damage)

[font_size=18][color=green]💚 HEALING CARDS:[/color][/font_size]
• Restore your lost health
• Can be used even exceeding your max health
• Examples: Bandage (2 health), Major Potion (8 health)

[font_size=18][color=cyan]🛡️ SHIELD CARDS:[/color][/font_size]
• Absorb incoming damage
• Stack if used consecutively
• Don't regenerate automatically
• Examples: Block (2 shield), Reinforced Shield (6 shield)""",

	"⭐ Rarity System": """[font_size=24][color=yellow]💎 CARD RARITY[/color][/font_size]

[font_size=18][color=white]⚪ COMMON (White):[/color][/font_size]
• Basic balanced cards
• Appear frequently
• Simple but useful effects
• Example: Basic Strike, Bandage

[font_size=18][color=green]🟢 UNCOMMON (Green):[/color][/font_size]
• More powerful effects than common cards
• Appear occasionally
• More visual shine
• Example: Sharp Sword, Potion

[font_size=18][color=cyan]🔵 RARE (Blue):[/color][/font_size]
• Very powerful cards
• Only appear sometimes
• Distinctive blue glow
• Example: Critical Strike, Major Heal

[font_size=18][color=magenta]🟣 EPIC (Purple):[/color][/font_size]
• Most powerful in the game
• Devastating effects
• Example: Annihilation (20 damage), Regeneration (12 health)""",

	"🎚️ Difficulty Levels": """[font_size=24][color=yellow]⚖️ AVAILABLE DIFFICULTIES[/color][/font_size]

[font_size=18][color=green]🟢 NORMAL:[/color][/font_size]
[color=lightblue]👤 Player:[/color] 35 HP, 10 Mana, 2 cards/turn, 5 in hand
[color=orange]🤖 AI:[/color] 35 HP, 10 Mana, balanced strategy

[font_size=18][color=orange]🟠 HARD:[/color][/font_size]
[color=lightblue]👤 Player:[/color] 33 HP, 10 Mana, 1 card/turn, 5 in hand
[color=orange]🤖 AI:[/color] 35 HP, 10 Mana, aggressive strategy

[font_size=18][color=red]🔴 EXPERT:[/color][/font_size]
[color=lightblue]👤 Player:[/color] 30 HP, 8 Mana, 1 card/turn, 4 in hand
[color=orange]🤖 AI:[/color] 38 HP, 12 Mana, brutal strategy""",

	"⚔️ Combat System": """[font_size=24][color=yellow]🎲 COMBAT MECHANICS[/color][/font_size]

[font_size=18][color=cyan]💥 DAMAGE & SHIELD:[/color][/font_size]
• Shield absorbs damage before health
• If damage exceeds shield, the difference goes to health
• Stack shields using multiple cards

[font_size=18][color=red]🔥 DAMAGE BONUS:[/color][/font_size]
• [color=orange]Turn 4:[/color] +1 damage to all attacks
• [color=orange]Turn 7:[/color] +2 damage to all attacks  
• [color=orange]Turn 10:[/color] +3 damage to all attacks
• [color=orange]Turn 15+:[/color] +4 damage to all attacks
• After reaching these thresholds, the bonus applies automatically to all combatants

[font_size=18][color=green]🔄 CARD RECYCLING:[/color][/font_size]
• When the deck is empty, used cards are reshuffled
• You'll never run completely out of options
• Strategy changes based on available cards
• Generally, card recycling and drawing is automatic, no action required""",

	"🎮 Controls": """[font_size=24][color=yellow]🕹️ GAME CONTROLS[/color][/font_size]

[font_size=18][color=orange]🎯 IN-GAME CONTROLS:[/color][/font_size]
[font_size=16][color=white]With Controller:[/color][/font_size]
- [color=lime]Left/Right:[/color] Navigate between cards
- [color=lime]A:[/color] Play selected card
- [color=lime]B:[/color] End turn
- [color=lime]X:[/color] Restart match
- [color=lime]Y:[/color] Return to main menu
- [color=lime]START:[/color] View key mapping

[font_size=16][color=white]With Keyboard/Mouse:[/color][/font_size]
- [color=lime]Click on card:[/color] Play card
- [color=lime]Click "End Turn":[/color] End turn
- [color=lime]R:[/color] Restart match
- [color=lime]ESC:[/color] Return to main menu
- [color=lime]H:[/color] View key mapping"""
}

func _ready():
	setup_topics()
	setup_buttons()
	
	await handle_scene_entrance()
	
	if topics_buttons_container.get_child_count() > 0:
		topics_buttons_container.get_child(0).grab_focus()

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and 
			TransitionManager.current_overlay.is_ready() and 
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):
			
			await TransitionManager.current_overlay.fade_out(0.3)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

func setup_topics():
	var first_topic = true
	
	for topic_name in help_topics.keys():
		var topic_button = Button.new()
		topic_button.text = topic_name
		topic_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		topic_button.custom_minimum_size.y = 45
		topic_button.add_theme_font_size_override("font_size", 14)
		topic_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		topics_buttons_container.add_child(topic_button)
		
		topic_button.pressed.connect(_on_topic_selected.bind(topic_name, topic_button))
		topic_button.mouse_entered.connect(_on_button_hover.bind(topic_button))
		topic_button.focus_entered.connect(_on_button_focus.bind(topic_button))
		
		if first_topic:
			_on_topic_selected(topic_name, topic_button)
			first_topic = false

func setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(_on_button_hover.bind(back_button))
	back_button.focus_entered.connect(_on_button_focus.bind(back_button))

func _on_topic_selected(topic_name: String, button: Button):
	if selected_topic_button:
		selected_topic_button.modulate = Color.WHITE
	
	selected_topic_button = button
	button.modulate = Color(1.2, 1.2, 0.8, 1)
	
	content_label.text = help_topics[topic_name]
	
	play_ui_sound("select")

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 0.8)

func _on_button_hover(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.1)
	
	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	play_hover_sound()

func play_ui_sound(sound_type: String):
	match sound_type:
		"button_click", "select":
			if ui_player.stream != preload("res://audio/ui/button_click.wav"):
				ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
		_:
			pass

func play_hover_sound():
	pass

func _input(event):
	if is_transitioning:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("gamepad_cancel"):
		_on_back_pressed()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("gamepad_accept"):
		if back_button.has_focus():
			_on_back_pressed()
		else:
			for child in topics_buttons_container.get_children():
				if child.has_focus():
					child.pressed.emit()
					break
