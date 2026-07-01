# Comandos de Ejecución Local

Esta guía contiene los comandos necesarios para levantar los entornos virtuales (venv) y ejecutar tanto el Backend como el componente IoT de forma independiente.

## 1. Backend (FastAPI)

**Windows (PowerShell):**
```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload

**LINUX**
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

#IoT Device
**WINDOWS**
cd iot_device
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python mqtt_bridge.py

**LINUX**
cd iot_device
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 mqtt_bridge.py