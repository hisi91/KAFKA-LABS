# Accéder à Control Center via trycloudflare

## Contexte

Le proxy d'entreprise bloque les ports non-standard. Cette solution utilise **Cloudflare Tunnel** pour exposer les services internes via HTTPS (port 443).

```
Navigateur (entreprise)
        ↓  (HTTPS 443 ✅)
trycloudflare.com
        ↓
Machine IDE (container VS Code)
        ↓
VM Docker (10.0.0.x) → Services exposés
```

---

## Prérequis

- Accès à un terminal sur la machine IDE (container VS Code)
- La VM Docker est accessible depuis la machine IDE via son IP privée

---

## Installation

> À faire **une seule fois**

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
```

---

## Script `tunnel.sh`

> À créer **une seule fois**

```bash
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
echo "⏱️  Arrêt automatique dans 10 minutes (en arrière-plan)"
echo ""

(
  sleep 600
  echo ""
  echo "🛑 Arrêt des tunnels..."
  for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null
  done
  rm -rf "$LOG_DIR"
  echo "✅ Tunnels arrêtés."
) &
```

```bash
chmod +x tunnel.sh
```

---

## Utilisation

```bash
./tunnel.sh <ip-privée-vm>

# Exemple :
./tunnel.sh 10.0.0.155
```

### Résultat attendu

```
✅ Tunnels actifs :
-----------------------------------
  Port 3000  → https://xxxx.trycloudflare.com
  Port 9021  → https://yyyy.trycloudflare.com  ← Control Center
  Port 9090  → https://zzzz.trycloudflare.com  ← Prometheus
-----------------------------------
⏱️  Arrêt automatique dans 10 minutes (en arrière-plan)
```

Ouvre l'URL correspondante dans ton navigateur. ✅

---

## Ports exposés

| Port | Service |
|------|---------|
| `3000` | Grafana |
| `9021` | Confluent Control Center |
| `9090` | Prometheus |

---

## Limites

> ⚠️ À garder en tête

- Les **URLs changent** à chaque lancement
- Tunnel s'arrête après **10 minutes** (modifiable dans le script via `sleep 600`)
- **Aucune garantie d'uptime** — usage expérimental uniquement
- **Aucune authentification** — ne pas exposer de données sensibles en production
- Soumis aux [CGU Cloudflare](https://www.cloudflare.com/website-terms/)
