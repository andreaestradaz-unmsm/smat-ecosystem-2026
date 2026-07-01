import paho.mqtt.client as mqtt
import requests
import json
import time
import threading
import sys

# --- 1. CONFIGURACIÓN ---
BROKER = "broker.hivemq.com"
# Se ajusta el tópico según las especificaciones del Laboratorio 11
TOPIC = "fisi/smat/estaciones/+/lecturas" 
API_URL = "http://localhost:8000/lecturas/"

# Configuración para la captura automática del token
LOGIN_URL = "http://localhost:8000/token"
API_USER = "tu_usuario_backend" 
API_PASS = "tu_contraseña_backend"

# --- 2. CAPTURA AUTOMÁTICA DEL TOKEN ---
print("Autenticando con el backend para obtener el JWT...")
try:
    login_response = requests.post(LOGIN_URL, data={"username": API_USER, "password": API_PASS})
    if login_response.status_code == 200:
        TOKEN = login_response.json().get("access_token")
        print("✅ Token capturado exitosamente por el script.")
    else:
        print(f"❌ Error al obtener el token: {login_response.text}")
        sys.exit(1)
except Exception as e:
    print(f"❌ No se pudo establecer conexión para la autenticación: {e}")
    sys.exit(1)

# --- 3. MEMORIA CACHÉ LOCAL (RETO Y ALERTAS) ---
last_seen = {}          # Monitoreo Offline: Registra la última actividad MQTT de la estación
last_saved_value = {}   # Filtro Deadband: Último valor persistido en la DB cloud
last_saved_time = {}    # Filtro Deadband: Timestamp de la última inserción en la DB cloud

# --- 4. LÓGICA INTERNA DEL BRIDGE ---
def on_message(client, userdata, msg):
    try:
        # Decodificar el payload binario de MQTT a JSON string
        payload_raw = msg.payload.decode("utf-8")
        payload = json.loads(payload_raw)
        
        # Extraer el ID dinámico de la estación basado en la estructura del tópico
        # Ejemplo: "fisi/smat/estaciones/5/lecturas" -> split('/') -> elemento en índice 3 es "5"
        topic_parts = msg.topic.split('/')
        estacion_id = int(topic_parts[3])
        valor_actual = float(payload["valor"])
        
        print(f"📥 Telemetría recibida de Estación [{estacion_id}]: {payload}")
        
        # Actualizar presencia inmediatamente (independientemente de si el dato se filtra o no)
        last_seen[estacion_id] = time.time()
        
        # --- IMPLEMENTACIÓN DEL FILTRO DE RUIDO (RETO) ---
        tiempo_actual = time.time()
        enviar_dato = False
        
        if estacion_id not in last_saved_value:
            # Primer dato registrado en esta sesión para la estación
            enviar_dato = True 
        else:
            ultimo_valor = last_saved_value[estacion_id]
            ultimo_tiempo = last_saved_time[estacion_id]
            
            # Condición 1: Variación mayor al ±5%
            variacion = abs(valor_actual - ultimo_valor)
            limite_variacion = 0.05 * ultimo_valor
            
            if variacion > limite_variacion:
                print(f"⚠️ Variación significativa detectada (> 5%) en Estación [{estacion_id}].")
                enviar_dato = True
                
            # Condición 2: Reporte mínimo de vida (Pasaron más de 60 segundos)
            elif (tiempo_actual - ultimo_tiempo) > 60:
                print(f"⏱️ Reporte mínimo de vida alcanzado (> 60s) para Estación [{estacion_id}].")
                enviar_dato = True
            else:
                print(f"🛑 Transmisión de Estación [{estacion_id}] omitida (Dato redundante dentro del umbral).")
        
        # --- PROCESO DE INGESTIÓN HTTP POST ---
        if enviar_dato:
            data_to_send = {
                "valor": valor_actual,
                "estacion_id": estacion_id
            }
            
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {TOKEN}"
            }
            
            response = requests.post(API_URL, json=data_to_send, headers=headers)
            
            if response.status_code in [200, 201]:
                print(f"💾 [DB Sincronizada] Estación [{estacion_id}]: {valor_actual} cm guardado con éxito.")
                # Actualizar los valores de la caché tras guardar exitosamente
                last_saved_value[estacion_id] = valor_actual
                last_saved_time[estacion_id] = tiempo_actual
            else:
                print(f"❌ Error API ({response.status_code}): {response.text}")
                
    except KeyError as e:
        print(f"⚠️ Error de esquema: Falta la clave {e} en el payload de origen.")
    except ValueError:
        print("⚠️ Error de casteo: El identificador o la lectura de la estación presentan problemas de formato.")
    except Exception as e:
        print(f"🚨 Error inesperado al procesar el mensaje: {e}")

# --- 5. MONITOREO DE ESTADO OFFLINE ---
def check_deadlines():
    while True:
        current_time = time.time()
        for eid, t in list(last_seen.items()):
            # Alerta si la estación deja de emitir al broker por completo durante 30 segundos
            if current_time - t > 30: 
                print(f"🚨 ALERTA CRÍTICA: Estación [{eid}] se encuentra OFFLINE (Sin señales MQTT).")
        time.sleep(10)

# Lanzar el hilo secundario de monitoreo
threading.Thread(target=check_deadlines, daemon=True).start()

# --- 6. INICIALIZACIÓN CLIENTE MQTT ---
client = mqtt.Client()
client.on_message = on_message

try:
    print("🚀 Inicializando el Bridge de Acoplamiento SMAT...")
    client.connect(BROKER, 1883, 60)
    client.subscribe(TOPIC)
    print(f"📡 Escuchando transmisiones activas en: {TOPIC}")
    client.loop_forever()
except KeyboardInterrupt:
    print("\n🛑 Bridge detenido por el administrador.")