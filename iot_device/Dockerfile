FROM python:3.10-slim

WORKDIR /app

# Copiamos e instalamos dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos los scripts de IoT
COPY . .

# Por defecto ejecutaremos el bridge (puedes cambiarlo si tu lab exige otro script)
CMD ["python", "mqtt_bridge.py"]