extends CanvasLayer

var overlay: ColorRect
var loading_container: Control
var loading_icon: TextureRect
var rotation_tween: Tween

func _ready():
	layer = 1000

	overlay = get_node("Overlay")
	loading_container = get_node("LoadingContainer")
	loading_icon = get_node("LoadingContainer/LoadingIcon")
	
	if not overlay:
		push_error("Overlay node not found in TransitionOverlay")
		return
	if not loading_container:
		push_error("LoadingContainer node not found in TransitionOverlay")
		return
	if not loading_icon:
		push_error("LoadingIcon node not found in TransitionOverlay")
		return
	
	#loading_icon.pivot_offset = Vector2(64, 64)
	
	overlay.color.a = 0.0
	loading_container.modulate.a = 0.0
	loading_icon.rotation = 0.0
	
	print("TransitionOverlay initialized correctly")

func start_loading_animation():
	if rotation_tween:
		rotation_tween.kill()
	
	loading_icon.rotation = 0.0
	
	rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_LINEAR)
	rotation_tween.tween_property(loading_icon, "rotation", TAU, 1.5)

func stop_loading_animation():
	if rotation_tween:
		rotation_tween.kill()
		rotation_tween = null
	
	var reset_tween = create_tween()
	reset_tween.tween_property(loading_icon, "rotation", 0.0, 0.2)

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
	return overlay != null and loading_container != null and loading_icon != null
