#!/bin/bash

# ==== CONFIGURATION ====
APP_DIR="/opt/hexonode-monitor"
REPO_URL="https://github.com/akaboydeve/vps_control.git"
SERVICE_NAME="hexonode-api"
PORT=1234

echo "🔐 Hexonode Control Panel Installer"

# Prompt for API token
read -p "Enter the API token to secure the endpoints: " API_TOKEN
if [[ -z "$API_TOKEN" ]]; then
  echo "❌ API token is required. Aborting."
  exit 1
fi

# Update & install dependencies
echo "🔧 Installing dependencies..."
sudo apt update && sudo apt install -y python3 python3-pip git

# Clone repo
echo "📥 Cloning repo into $APP_DIR..."
sudo rm -rf "$APP_DIR"
sudo git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR" || exit 1

# Create .env with token
echo "🔑 Writing .env..."
echo "API_TOKEN=$API_TOKEN" | sudo tee "$APP_DIR/.env" > /dev/null

# Install Python packages
echo "📦 Installing Python packages..."
pip install fastapi uvicorn psutil python-dotenv

# Create systemd service
echo "⚙️ Setting up systemd service..."
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
echo "[Unit]
Description=hexonode control panel system
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port $PORT
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target" | sudo tee "$SERVICE_FILE" > /dev/null

# Enable + start service
echo "🚀 Starting service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# Final status
echo "✅ Installation complete. API is running on port $PORT"
echo "🔁 To check status: sudo systemctl status $SERVICE_NAME"
