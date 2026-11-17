#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/tezfood}"
BACKEND_DIR="$APP_DIR/backend"
VENV_DIR="$BACKEND_DIR/.venv"
PORT="${PORT:-8080}"
SERVICE_NAME="${SERVICE_NAME:-tezfood}"

cd "$APP_DIR"

echo "==> Git pull"
git fetch --all
git reset --hard origin/master 2>/dev/null || git reset --hard origin/main

echo "==> Python venv"
python3 -m venv "$VENV_DIR"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r "$BACKEND_DIR/requirements.txt"

echo "==> Systemd service"
cat >/etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=TEZ FOOD FastAPI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${BACKEND_DIR}
Environment=PORT=${PORT}
Environment=ADMIN_PIN=2468
Environment=KASSA_PIN=1357
ExecStart=${VENV_DIR}/bin/python -m uvicorn main:app --host 0.0.0.0 --port ${PORT}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"
sleep 2
systemctl --no-pager --full status "${SERVICE_NAME}" || true

echo "==> Health check"
curl -fsS "http://127.0.0.1:${PORT}/api/health" || true
echo
echo "Deploy tayyor: http://$(hostname -I | awk '{print $1}'):${PORT}"
