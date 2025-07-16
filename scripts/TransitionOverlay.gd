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
		push_error("No se encontró el nodo Overlay en TransitionOverlay")
		return
	if not loading_container:
		push_error("No se encontró el nodo LoadingContainer en TransitionOverlay")
		return
	if not loading_icon:
		push_error("No se encontró el nodo LoadingIcon en TransitionOverlay")
		return
	
	# Configurar el pivot al centro para rotación correcta
	loading_icon.pivot_offset = Vector2(64, 64)  # Centro del contenedor de 128x128
	
	overlay.color.a = 0.0
	loading_container.modulate.a = 0.0
	loading_icon.rotation = 0.0
	
	print("TransitionOverlay inicializado correctamente")

func start_loading_animation():
	"""Inicia la animación de rotación del ícono de carga"""
	if rotation_tween:
		rotation_tween.kill()
	
	# Asegurar que la rotación inicial sea 0
	loading_icon.rotation = 0.0
	
	rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_LINEAR)
	rotation_tween.tween_property(loading_icon, "rotation", TAU, 1.5)  # Gira sobre su eje en 1.5 segundos

func stop_loading_animation():
	"""Detiene la animación de rotación"""
	if rotation_tween:
		rotation_tween.kill()
		rotation_tween = null
	
	# Resetear rotación suavemente
	var reset_tween = create_tween()
	reset_tween.tween_property(loading_icon, "rotation", 0.0, 0.2)

func fade_in(duration: float = 0.5):
	"""Fade a negro (ocultar escena actual) y mostrar loading"""
	if not overlay or not loading_container:
		push_error("Nodos no disponibles en fade_in")
		return
	
	# Iniciar animación de carga
	start_loading_animation()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(overlay, "color:a", 1.0, duration)
	tween.tween_property(loading_container, "modulate:a", 1.0, duration * 0.8)
	
	await tween.finished

func fade_out(duration: float = 0.5):
	"""Fade desde negro (mostrar nueva escena) y ocultar loading"""
	if not overlay or not loading_container:
		push_error("Nodos no disponibles en fade_out")
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(overlay, "color:a", 0.0, duration)
	tween.tween_property(loading_container, "modulate:a", 0.0, duration * 0.6)
	
	await tween.finished
	
	# Detener animación cuando ya no es visible
	stop_loading_animation()

func instant_black():
	"""Mostrar overlay negro instantáneamente con loading"""
	if not overlay or not loading_container:
		push_error("Nodos no disponibles en instant_black")
		return
		
	overlay.color.a = 1.0
	loading_container.modulate.a = 1.0
	start_loading_animation()

func instant_clear():
	"""Ocultar overlay instantáneamente"""
	if not overlay or not loading_container:
		push_error("Nodos no disponibles en instant_clear")
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
