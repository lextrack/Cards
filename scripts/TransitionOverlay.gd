extends CanvasLayer

var overlay: ColorRect
var loading_container: Control
var card_container: Control
var card_front: ColorRect
var card_back: ColorRect
var rotation_tween: Tween
var is_animating: bool = false

var card_size = Vector2(80, 110)
var flip_duration = 0.8
var pause_duration = 0.3

func _ready():
	layer = 1000
	
	overlay = get_node("Overlay")
	loading_container = get_node("LoadingContainer")
	
	if not overlay:
		push_error("Overlay node not found in TransitionOverlay")
		return
	if not loading_container:
		push_error("LoadingContainer node not found in TransitionOverlay")
		return
	
	_create_card_animation()
	
	overlay.color.a = 0.0
	loading_container.modulate.a = 0.0
	
	print("TransitionOverlay with card animation initialized correctly")

func _create_card_animation():
	for child in loading_container.get_children():
		child.queue_free()
	
	card_container = Control.new()
	card_container.name = "CardContainer"
	card_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card_container.custom_minimum_size = card_size
	card_container.size = card_size
	card_container.position = -card_size / 2
	loading_container.add_child(card_container)

	card_front = ColorRect.new()
	card_front.name = "CardFront"
	card_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_front.color = Color(0.2, 0.4, 0.8, 1.0)
	card_front.z_index = 1
	card_container.add_child(card_front)
	
	var front_border = ColorRect.new()
	front_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	front_border.color = Color(1.0, 1.0, 1.0, 1.0)
	front_border.z_index = 0
	card_front.add_child(front_border)
	
	var front_inner = ColorRect.new()
	front_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	front_inner.offset_left = 2
	front_inner.offset_top = 2
	front_inner.offset_right = -2
	front_inner.offset_bottom = -2
	front_inner.color = Color(0.2, 0.4, 0.8, 1.0)
	front_border.add_child(front_inner)
	
	var front_symbol = Label.new()
	front_symbol.text = "⚔️"
	front_symbol.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	front_symbol.add_theme_font_size_override("font_size", 32)
	front_symbol.add_theme_color_override("font_color", Color.WHITE)
	front_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	front_symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	front_symbol.position = Vector2(-16, -16)
	front_symbol.size = Vector2(32, 32)
	card_front.add_child(front_symbol)
	
	card_back = ColorRect.new()
	card_back.name = "CardBack"
	card_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_back.color = Color(0.8, 0.2, 0.4, 1.0)
	card_back.z_index = 0
	card_back.visible = false
	card_container.add_child(card_back)
	
	var back_border = ColorRect.new()
	back_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_border.color = Color(1.0, 1.0, 1.0, 1.0)
	back_border.z_index = 0
	card_back.add_child(back_border)
	
	var back_inner = ColorRect.new()
	back_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_inner.offset_left = 2
	back_inner.offset_top = 2
	back_inner.offset_right = -2
	back_inner.offset_bottom = -2
	back_inner.color = Color(0.8, 0.2, 0.4, 1.0)
	back_border.add_child(back_inner)

	var back_pattern = Label.new()
	back_pattern.text = "🃏"
	back_pattern.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	back_pattern.add_theme_font_size_override("font_size", 28)
	back_pattern.add_theme_color_override("font_color", Color.WHITE)
	back_pattern.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_pattern.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back_pattern.position = Vector2(-14, -14)
	back_pattern.size = Vector2(28, 28)
	card_back.add_child(back_pattern)

func start_loading_animation():
	if rotation_tween:
		rotation_tween.kill()
	
	if not card_container:
		push_error("Card container not available for animation")
		return
	
	card_container.scale.x = 1.0
	card_front.visible = true
	card_back.visible = false
	card_front.z_index = 1
	card_back.z_index = 0
	
	is_animating = true
	_start_continuous_flip()

func _start_continuous_flip():
	if not is_animating:
		return
	_animate_card_flip.call_deferred()

func _animate_card_flip():
	if not card_container or not is_animating:
		return
	
	rotation_tween = create_tween()
	
	rotation_tween.tween_method(_update_card_flip, 0.0, 2.0, flip_duration)
	
	rotation_tween.tween_callback(_pause_animation.bind(pause_duration))
	
	rotation_tween.tween_callback(_start_continuous_flip)

func _pause_animation(duration: float):
	if not is_animating:
		return
	await get_tree().create_timer(duration).timeout

func _update_card_flip(progress: float):
	if not card_container or not card_front or not card_back:
		return
	
	var angle = progress * PI
	
	var scale_x = abs(cos(angle))

	scale_x = max(scale_x, 0.05)
	card_container.scale.x = scale_x
	
	var show_front = cos(angle) >= 0
	
	if show_front:
		card_front.visible = true
		card_back.visible = false
		card_front.z_index = 1
		card_back.z_index = 0
	else:
		card_front.visible = false
		card_back.visible = true
		card_front.z_index = 0
		card_back.z_index = 1
		card_container.scale.x = -scale_x
	
	var float_offset = sin(progress * PI * 2) * 1.5
	card_container.position.y = -card_size.y / 2 + float_offset

func stop_loading_animation():
	is_animating = false
	
	if rotation_tween:
		rotation_tween.kill()
		rotation_tween = null
	
	if card_container:
		var reset_tween = create_tween()
		reset_tween.set_parallel(true)
		reset_tween.tween_property(card_container, "scale:x", 1.0, 0.2)
		reset_tween.tween_property(card_container, "position:y", -card_size.y / 2, 0.2)
		
		if card_front and card_back:
			card_front.visible = true
			card_back.visible = false
			card_front.z_index = 1
			card_back.z_index = 0

func fade_in(duration: float = 0.5):
	if not overlay or not loading_container:
		push_error("Nodes not available in fade_in")
		return
	
	start_loading_animation()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(overlay, "color:a", 1.0, duration)
	tween.tween_property(loading_container, "modulate:a", 1.0, duration * 0.8)
	
	await tween.finished

func fade_out(duration: float = 0.5):
	if not overlay or not loading_container:
		push_error("Nodes not available in fade_out")
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(overlay, "color:a", 0.0, duration)
	tween.tween_property(loading_container, "modulate:a", 0.0, duration * 0.6)
	
	await tween.finished
	
	stop_loading_animation()

func instant_black():
	if not overlay or not loading_container:
		push_error("Nodes not available in instant_black")
		return
		
	overlay.color.a = 1.0
	loading_container.modulate.a = 1.0
	start_loading_animation()

func instant_clear():
	if not overlay or not loading_container:
		push_error("Nodes not available in instant_clear")
		return
		
	overlay.color.a = 0.0
	loading_container.modulate.a = 0.0
	stop_loading_animation()
	
func is_covering():
	if not overlay:
		return false
		
	return overlay.color.a > 0.5

func show_loading():
	instant_black()

func hide_loading():
	await fade_out(0.5)

func is_ready() -> bool:
	return overlay != null and loading_container != null and card_container != null

func set_card_colors(front_color: Color, back_color: Color):
	if card_front and card_back:
		var front_inner = card_front.get_child(0).get_child(0)
		var back_inner = card_back.get_child(0).get_child(0)
		
		if front_inner:
			front_inner.color = front_color
		if back_inner:
			back_inner.color = back_color

func set_flip_speed(new_duration: float):
	flip_duration = new_duration

func set_pause_duration(new_pause: float):
	pause_duration = new_pause
