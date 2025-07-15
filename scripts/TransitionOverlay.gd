extends CanvasLayer

var overlay: ColorRect
var loading_label: Label

func _ready():
	layer = 1000

	overlay = get_node("Overlay")
	loading_label = get_node("LoadingLabel")
	
	if not overlay:
		push_error("No se encontró el nodo Overlay en TransitionOverlay")
		return
	if not loading_label:
		push_error("No se encontró el nodo LoadingLabel en TransitionOverlay")
		return
	
	overlay.color.a = 0.0
	loading_label.modulate.a = 0.0
	
	print("TransitionOverlay inicializado correctamente")

func set_message(message: String):
	"""Configura el mensaje de carga"""
	if not loading_label:
		return
		
	loading_label.text = message
	loading_label.visible = message != ""

func fade_in(duration: float = 0.5):
	"""Fade a negro (ocultar escena actual)"""
	if not overlay:
		push_error("Overlay no disponible en fade_in")
		return
		
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(overlay, "color:a", 1.0, duration)

	if loading_label and loading_label.visible:
		tween.tween_property(loading_label, "modulate:a", 1.0, duration * 0.8)
	
	await tween.finished

func fade_out(duration: float = 0.5):
	"""Fade desde negro (mostrar nueva escena)"""
	if not overlay:
		push_error("Overlay no disponible en fade_out")
		return
		
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(overlay, "color:a", 0.0, duration)

	if loading_label:
		tween.tween_property(loading_label, "modulate:a", 0.0, duration * 0.6)
	
	await tween.finished

func instant_black():
	if not overlay:
		push_error("Overlay no disponible en instant_black")
		return
		
	overlay.color.a = 1.0
	
	if loading_label:
		loading_label.modulate.a = 1.0 if loading_label.visible else 0.0

func instant_clear():
	if not overlay:
		push_error("Overlay no disponible en instant_clear")
		return
		
	overlay.color.a = 0.0
	
	if loading_label:
		loading_label.modulate.a = 0.0

func is_covering():
	if not overlay:
		return false
		
	return overlay.color.a > 0.5

func show_loading(message: String = "Cargando..."):
	set_message(message)
	instant_black()

func hide_loading():
	await fade_out(0.5)

func is_ready() -> bool:
	return overlay != null and loading_label != null
