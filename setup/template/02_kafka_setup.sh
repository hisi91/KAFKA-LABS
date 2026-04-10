#!/bin/bash
# =============================================================
# Script KAFKA : installation plocate + Docker Compose v2
# Exécuter en tant que : kafka
# Usage : bash 02_kafka_setup.sh
# =============================================================

set -euo pipefail

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[KAFKA ✔]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN   ]${NC} $1"; }
die()  { echo -e "${RED}[ERROR  ]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# =============================================================
# Vérification : doit être exécuté par kafka (pas root)
# =============================================================
if [[ "$USER" != "kafka" ]]; then
  die "Ce script doit être exécuté en tant qu'utilisateur kafka. Actuel : $USER"
fi

# =============================================================
# ÉTAPE 1 : Installation de plocate
# =============================================================
step "ÉTAPE 1 : Installation de plocate"
sudo apt install -y plocate
log "plocate installé."

# =============================================================
# ÉTAPE 2 : Prérequis Docker
# =============================================================
step "ÉTAPE 2 : Installation des prérequis Docker"
sudo apt update
sudo apt install -y ca-certificates curl
log "Prérequis installés."

# =============================================================
# ÉTAPE 3 : Clé GPG Docker
# =============================================================
step "ÉTAPE 3 : Ajout de la clé GPG Docker"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
log "Clé GPG ajoutée."

# =============================================================
# ÉTAPE 4 : Ajout du dépôt Docker
# =============================================================
step "ÉTAPE 4 : Ajout du dépôt Docker"

. /etc/os-release
UBUNTU_CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
ARCH="$(dpkg --print-architecture)"

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

log "Dépôt Docker ajouté (Ubuntu: ${UBUNTU_CODENAME}, arch: ${ARCH})."

# =============================================================
# ÉTAPE 5 : Installation Docker Engine + Compose v2
# =============================================================
step "ÉTAPE 5 : Installation Docker Engine + plugin compose"
sudo apt update
sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin        # ← le groupe 'docker' est créé ici

log "Docker Engine + docker-compose-plugin installés."

# Vérification que le service tourne
sudo systemctl enable docker
sudo systemctl start docker
log "Service Docker démarré."

# =============================================================
# ÉTAPE 6 : Ajout de kafka au groupe docker
# =============================================================
step "ÉTAPE 6 : Ajout de kafka au groupe docker"

# Sécurité : vérification que le groupe existe bien maintenant
if ! getent group docker > /dev/null; then
  die "Le groupe 'docker' n'existe toujours pas après installation — vérifiez l'install Docker."
fi

sudo usermod -aG docker kafka
log "kafka ajouté au groupe docker."

# =============================================================
# ÉTAPE 7 : Vérifications finales
# =============================================================
step "ÉTAPE 7 : Vérifications finales"
docker compose version && log "Docker Compose v2 ✅"
sudo docker run --rm hello-world && log "Docker Engine opérationnel ✅"

# =============================================================
# RÉSUMÉ
# =============================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ ÉTAPE KAFKA TERMINÉE${NC}"
echo -e "${GREEN}============================================${NC}"
log "plocate installé"
log "Docker Engine installé"
log "Docker Compose v2 installé"
log "kafka ajouté au groupe docker"
echo ""
warn "⚠️  Déconnecte/reconnecte ta session pour activer le groupe docker :"
echo -e "   exit  →  su - kafka"
echo -e "   Puis teste sans sudo : ${BLUE}docker compose version${NC}"
echo -e "${GREEN}============================================${NC}"