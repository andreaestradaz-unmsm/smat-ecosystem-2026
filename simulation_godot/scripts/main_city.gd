extends Node3D

# Referencias a los nodos
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var visualizacion_satelital: Node2D = $VisualizacionSatelital

# URL del backend 
const BACKEND_URL : String = "http://127.0.0.1:8000/app/datos_ambientales" 
const LOGIN_URL : String = "http://127.0.0.1:8000/api/usuarios/login"

var auth_token : String = ""
var is_logging_in : bool = false

func _ready() -> void:
	print("¡Gemelo Digital inicializado con éxito!")
	http_request.request_completed.connect(_on_request_completed)
	actualizar_contaminacion(0.25, Color(1, 1, 1)) 
	iniciar_sesion()

func iniciar_sesion() -> void:
	print("Iniciando sesión en el backend como admin...")
	is_logging_in = true
	var body = "username=admin&password=admin"
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var error = http_request.request(LOGIN_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("Error al intentar enviar request de login.")

func realizar_peticion_backend() -> void:
	print("Solicitando datos al backend...")
	is_logging_in = false
	var headers = ["Authorization: Bearer " + auth_token]
	var error = http_request.request(BACKEND_URL, headers)
	if error != OK:
		print("Error al intentar iniciar la petición HTTP.")

# Dividimos los argumentos en líneas para evitar cortes y limpiar warnings de variables no usadas
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if is_logging_in:
		if response_code == 200:
			var json_texto = body.get_string_from_utf8()
			var json = JSON.parse_string(json_texto)
			if json and json.has("access_token"):
				auth_token = json["access_token"]
				print("Login exitoso. Solicitando datos...")
				realizar_peticion_backend()
		else:
			print("Error en login. Código: ", response_code)
			# Reintentar login en 5 segundos si falla
			await get_tree().create_timer(5.0).timeout
			iniciar_sesion()
	else:
		if response_code == 200:
			var json_texto = body.get_string_from_utf8()
			var json = JSON.parse_string(json_texto)
			
			if json and json.has("pm25"):
				var nivel_pm25 = json["pm25"]
				var color_clima = Color(0.3, 0.3, 0.3) if nivel_pm25 > 0.1 else Color(1, 1, 1)
				actualizar_contaminacion(nivel_pm25, color_clima)
		else:
			print("No se pudo conectar al backend. Código de respuesta: ", response_code)
			if response_code == 401:
				print("Token expirado, reiniciando sesión...")
				iniciar_sesion()
				return
		
		# Esperar 5 segundos y volver a consultar los datos para que se actualice en tiempo real
		await get_tree().create_timer(5.0).timeout
		realizar_peticion_backend()

func actualizar_contaminacion(nivel_pm25: float, color_humo: Color) -> void:
	if world_environment and world_environment.environment:
		world_environment.environment.volumetric_fog_density = nivel_pm25
		world_environment.environment.volumetric_fog_albedo = color_humo
		print("Atmósfera sincronizada con el Backend. Densidad: ", nivel_pm25)
	
	if visualizacion_satelital and visualizacion_satelital.has_method("actualizar_por_valor"):
		visualizacion_satelital.actualizar_por_valor(nivel_pm25)
