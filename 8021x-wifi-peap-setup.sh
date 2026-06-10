#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo" >&2
  exit 1
fi

read -rp "SSID: " SSID
read -rp "Username: " USERNAME
read -rsp "Password: " PASSWORD
echo

if ! command -v iwd &>/dev/null; then
  echo "Installing iwd..."
  pacman -S --noconfirm iwd
fi

mkdir -p /var/lib/iwd

CONFIG="/var/lib/iwd/${SSID}.8021x"

if [[ -f "$CONFIG" ]]; then
  cp "$CONFIG" "${CONFIG}.bak.$(date +%F_%H%M%S)"
  echo "Backed up existing config"
fi

cat > "$CONFIG" << EOF
[Security]
EAP-Method=PEAP
EAP-Identity=${USERNAME}
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=${USERNAME}
EAP-PEAP-Phase2-Password=${PASSWORD}

[Settings]
AutoConnect=true
EOF

chmod 600 "$CONFIG"
echo "Installed $CONFIG"

systemctl enable --now iwd.service

echo "Done. Connect with: iwctl station wlan0 connect ${SSID}"
