#!/bin/bash
# =============================================================
# Script ROOT : création user kafka + préparation système
# Exécuter en tant que : root
# Usage : sudo bash 01_root_setup.sh
# =============================================================

set -euo pipefail

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ROOT ✔]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN  ]${NC} $1"; }
die()  { echo -e "${RED}[ERROR ]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# =============================================================
# Vérification : must be root
# =============================================================
if [[ "$EUID" -ne 0 ]]; then
  die "Ce script doit être exécuté en tant que root → sudo bash $0"
fi

# =============================================================
# ÉTAPE 1 : Mise à jour système
# =============================================================
step "ÉTAPE 1 : Mise à jour du système"
apt update && apt upgrade -y
log "Système mis à jour."

# =============================================================
# ÉTAPE 2 : Création de l'utilisateur kafka
# =============================================================
step "ÉTAPE 2 : Création de l'utilisateur kafka"

if id "kafka" &>/dev/null; then
  warn "L'utilisateur 'kafka' existe déjà — création ignorée."
else
  adduser --gecos "" --disabled-password kafka
  echo "kafka:matmut2026_" | chpasswd
  log "Utilisateur kafka créé. Mot de passe temporaire : matmut2026_"
fi

log "Vérification :"
id kafka
grep kafka /etc/passwd

# =============================================================
# ÉTAPE 3 : Ajout au groupe sudo
# =============================================================
step "ÉTAPE 3 : Ajout de kafka au groupe sudo"
usermod -aG sudo kafka
log "Groupes actuels de kafka : $(groups kafka)"

# =============================================================
# ÉTAPE 4 : Copie du script kafka sur le bon home
# =============================================================
step "ÉTAPE 4 : Préparation du script kafka"

KAFKA_SCRIPT_SRC="$(dirname "$0")/02_kafka_setup.sh"
KAFKA_SCRIPT_DST="/home/kafka/02_kafka_setup.sh"

if [[ -f "$KAFKA_SCRIPT_SRC" ]]; then
  cp "$KAFKA_SCRIPT_SRC" "$KAFKA_SCRIPT_DST"
  chown kafka:kafka "$KAFKA_SCRIPT_DST"
  chmod 750 "$KAFKA_SCRIPT_DST"
  log "Script kafka copié vers $KAFKA_SCRIPT_DST"
else
  warn "02_kafka_setup.sh introuvable à côté de ce script — copie ignorée."
  warn "Pense à copier manuellement 02_kafka_setup.sh dans /home/kafka/"
fi

# =============================================================
# ÉTAPE 4 : Autoriser la connexion SSH par mot de passe pour kafka
# =============================================================
step "ÉTAPE 4 : Configuration SSH pour kafka"

SSHD_CONFIG="/etc/ssh/sshd_config"

# Sauvegarde avant modification
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"
log "Sauvegarde créée : ${SSHD_CONFIG}.bak"


# Activer PasswordAuthentication globalement si désactivé ou commenté
if grep -q "^PasswordAuthentication no" "$SSHD_CONFIG"; then
  # Cas 1 : explicitement à no → on passe à yes
  sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$SSHD_CONFIG"
  log "PasswordAuthentication : no → yes."

elif grep -q "^#.*PasswordAuthentication" "$SSHD_CONFIG"; then
  # Cas 2 : ligne commentée → on décommente et on met yes
  sed -i 's/^#.*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
  log "PasswordAuthentication décommenté et mis à yes."

else
  # Cas 3 : ligne absente → on l'ajoute
  echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
  log "PasswordAuthentication yes ajouté dans sshd_config."
fi

# Ajouter un bloc Match User kafka en fin de fichier (si pas déjà présent)
if ! grep -q "Match User kafka" "$SSHD_CONFIG"; then
  cat >> "$SSHD_CONFIG" <<EOF

# Connexion SSH par mot de passe autorisée pour kafka
Match User kafka
    PasswordAuthentication yes
EOF
  log "Bloc 'Match User kafka' ajouté dans sshd_config."
else
  warn "Bloc 'Match User kafka' déjà présent — aucune modification."
fi

# Vérification syntaxe avant reload
sshd -t && log "Syntaxe sshd_config valide." || die "Erreur de syntaxe dans sshd_config — vérifiez ${SSHD_CONFIG}"

# Rechargement SSH
systemctl reload sshd
log "Service SSH rechargé."

# =============================================================
# RÉSUMÉ
# =============================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ ÉTAPE ROOT TERMINÉE${NC}"
echo -e "${GREEN}============================================${NC}"
log "Système mis à jour"
log "Utilisateur kafka créé"
log "kafka ajouté au groupe sudo"
echo ""
warn "⚠️  Change le mot de passe kafka en prod : passwd kafka"
echo ""
echo -e "${BLUE}👉 Prochaine étape — connecte-toi en tant que kafka :${NC}"
echo -e "   su - kafka"
echo -e "   bash 02_kafka_setup.sh"
echo -e "${GREEN}============================================${NC}"