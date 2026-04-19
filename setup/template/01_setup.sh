#!/bin/bash

# =============================================================================
# Script : Installation Ansible + Patch inventaire + Lancement playbooks
# =============================================================================

set -euo pipefail

INVENTORY="/home/$USER/formation/inventory_participants"
SSH_KEY_PARAM="ansible_ssh_private_key_file=/home/$USER/formation/.ssh/id_rsa"
PLAYBOOKS=(
    "02_playbook.yml"
    # Ajoute d'autres playbooks ici si besoin :
    # "02_deploy_playbook.yml"
)

# -----------------------------------------------------------------------------
# Couleurs pour les logs
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# -----------------------------------------------------------------------------
# 1. Installation d'Ansible
# -----------------------------------------------------------------------------
log_info "Mise à jour des paquets..."
sudo apt update -y

log_info "Installation d'Ansible..."
sudo apt install -y ansible

ansible --version | head -1 && log_ok "Ansible installé avec succès."

# -----------------------------------------------------------------------------
# 2. Patch du fichier inventaire
# -----------------------------------------------------------------------------
if [[ ! -f "$INVENTORY" ]]; then
    log_error "Fichier inventaire introuvable : $INVENTORY"
    exit 1
fi

log_info "Patch de l'inventaire : $INVENTORY"

# Sauvegarde
cp "$INVENTORY" "${INVENTORY}.bak"
log_info "Sauvegarde créée : ${INVENTORY}.bak"

# Pour chaque ligne contenant une IP (pattern: commence par un chiffre),
# on vérifie si la clé SSH est déjà présente ; sinon on l'insère après l'IP.
python3 - <<PYEOF
import re, sys

inventory_path = "/home/$USER/formation/inventory_participants"
ssh_key_param  = "ansible_ssh_private_key_file=/home/$USER/formation/.ssh/id_rsa"

with open(inventory_path, "r") as f:
    lines = f.readlines()

patched = []
ip_pattern = re.compile(r'^(\d{1,3}(?:\.\d{1,3}){3})([ \t]+.*)?$')

for line in lines:
    stripped = line.rstrip("\n")
    m = ip_pattern.match(stripped)
    if m and ssh_key_param not in stripped:
        ip   = m.group(1)
        rest = m.group(2) or ""
        # On reconstruit : IP  ansible_ssh_private_key_file=...  reste
        stripped = f"{ip} {ssh_key_param}{rest}"
    patched.append(stripped + "\n")

with open(inventory_path, "w") as f:
    f.writelines(patched)

print("Inventaire patché avec succès.")
PYEOF

log_ok "Inventaire mis à jour."
echo ""
log_info "Contenu de l'inventaire après patch :"
cat "$INVENTORY"
echo ""

# -----------------------------------------------------------------------------
# 3. Lancement des playbooks avec sudo
# -----------------------------------------------------------------------------
for playbook in "${PLAYBOOKS[@]}"; do
    if [[ ! -f "$playbook" ]]; then
        log_warn "Playbook introuvable, ignoré : $playbook"
        continue
    fi

    log_info "Lancement du playbook : $playbook"
    sudo ansible-playbook -i "$INVENTORY" "$playbook"
    log_ok "Playbook terminé : $playbook"
done

log_ok "Toutes les étapes sont complètes."