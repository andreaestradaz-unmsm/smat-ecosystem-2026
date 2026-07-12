extends Node2D

# Referencias exactas a tus Sprites en la escena actual
@onready var nube_contaminacion: Sprite2D = $NubeContaminacion

# Niveles de contaminación
enum NivelContaminacion { LIMPIO, INTERMEDIO, ALTO }

# Colores con opacidad (Alpha) para teñir tu nube traslúcida sobre la Av. Venezuela
const COLOR_VERDE_NUBE = Color(0.0, 1.0, 0.2, 0.4)    # Contaminación baja
const COLOR_NARANJA_NUBE = Color(1.0, 0.6, 0.0, 0.65)  # Contaminación moderada
const COLOR_ROJO_NUBE = Color(0.9, 0.0, 0.0, 0.75)     # Contaminación crítica

func _ready():
	# Forzamos una prueba inicial en ALTO (Rojo) para verificar la transparencia
	actualizar_visualizacion(NivelContaminacion.ALTO)

# Función lista para conectar con los datos de tu Backend (PPM)
func actualizar_por_valor(ppm_value: float):
	if ppm_value < 50.0:
		actualizar_visualizacion(NivelContaminacion.LIMPIO)
	elif ppm_value >= 50.0 and ppm_value < 150.0:
		actualizar_visualizacion(NivelContaminacion.INTERMEDIO)
	else:
		actualizar_visualizacion(NivelContaminacion.ALTO)

# Cambia el color de la nube sin alterar el mapa satelital de fondo
func actualizar_visualizacion(estado: NivelContaminacion):
	if not is_node_ready() or not nube_contaminacion: 
		return
		
	match estado:
		NivelContaminacion.LIMPIO:
			nube_contaminacion.modulate = COLOR_VERDE_NUBE
		NivelContaminacion.INTERMEDIO:
			nube_contaminacion.modulate = COLOR_NARANJA_NUBE
		NivelContaminacion.ALTO:
			nube_contaminacion.modulate = COLOR_ROJO_NUBE
