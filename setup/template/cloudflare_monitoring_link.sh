#!/bin/bash

VM_IP=$1

if [ -z "$VM_IP" ]; then
  echo "Usage: $0 <ip>"
  exit 1
fi

PORTS=(3000 9021 9090)
PIDS=()
LOG_DIR=$(mktemp -d)

echo "🚀 Ouverture des tunnels pour $VM_IP..."

for port in "${PORTS[@]}"; do
  log="$LOG_DIR/tunnel_${port}.log"
  ./cloudflared tunnel --url http://${VM_IP}:${port} > "$log" 2>&1 &
  PIDS+=($!)
done

echo "⏳ Attente des URLs..."

URLS=()
for port in "${PORTS[@]}"; do
  log="$LOG_DIR/tunnel_${port}.log"
  url=""
  for i in $(seq 1 30); do
    url=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$log" | head -1)
    if [ -n "$url" ]; then break; fi
    sleep 1
  done
  URLS+=("$url")
done

echo ""
echo "✅ Tunnels actifs :"
echo "-----------------------------------"
echo "  Port 3000  → ${URLS[0]}"
echo "  Port 9021  → ${URLS[1]}"
echo "  Port 9090  → ${URLS[2]}"
echo "-----------------------------------"
echo "⏱️  Arrêt automatique dans 10 minutes..."


# Kill après 10min en arrière-plan
(
  sleep 1200
  echo ""
  echo "🛑 Arrêt des tunnels..."
  for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null
  done
  rm -rf "$LOG_DIR"
  echo "✅ Tunnels arrêtés."
) &
