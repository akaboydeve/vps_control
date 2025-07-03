#!/bin/bash

# Ask for port
read -p "Enter the port you want to run the API on: " PORT

# Install pip and dependencies
echo "Installing Python and dependencies..."
sudo apt update -y
sudo apt install -y python3 python3-pip
python3 -m pip install --upgrade pip
pip install fastapi uvicorn --quiet

# Create the API directory and script
mkdir -p ~/ping_api_service
cd ~/ping_api_service

cat <<EOF > ping_api.py
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

app = FastAPI()

@app.get("/ping", response_class=PlainTextResponse)
async def ping():
    return "pong"
EOF

# Create the systemd service file
SERVICE_NAME=pingapi
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=Lightweight Ping API Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/ping_api_service
ExecStart=$(which uvicorn) ping_api:app --host 0.0.0.0 --port ${PORT}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload, enable, and start the service
echo "Setting up systemd service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "✅ Ping API is now running on port $PORT"
echo "🔁 It will restart automatically on system reboot."
