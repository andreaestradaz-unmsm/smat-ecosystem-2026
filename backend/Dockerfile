# Usamos una imagen oficial de Python ligera
FROM python:3.10-slim

# Establecemos el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos el archivo de dependencias primero
COPY requirements.txt .

# Instalamos las dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos todo el código de la carpeta backend al contenedor
COPY . .

# Exponemos el puerto donde correrá FastAPI
EXPOSE 8000

# Comando para iniciar el servidor FastAPI
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
