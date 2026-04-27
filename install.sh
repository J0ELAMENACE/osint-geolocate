#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  osint-geolocate — install script
#  Usage : sudo bash install.sh
# ─────────────────────────────────────────────────────────────

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERR ]${RESET}  $*"; exit 1; }

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="osint-geolocate"
SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)/${SCRIPT_NAME}"

echo
echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   osint-geolocate  —  installer      ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
echo

# ── 0. Root check ──────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
    error "Lancez le script avec sudo : sudo bash install.sh"
fi

# ── 1. Python 3 ────────────────────────────────────────────
info "Vérification Python 3..."
if ! command -v python3 &>/dev/null; then
    info "Installation de Python 3..."
    apt-get update -qq && apt-get install -y -qq python3 python3-pip
fi
PY_VERSION=$(python3 --version)
ok "$PY_VERSION"

# ── 2. pip ─────────────────────────────────────────────────
info "Vérification pip..."
if ! python3 -m pip --version &>/dev/null; then
    apt-get install -y -qq python3-pip
fi
ok "pip disponible"

# ── 3. Dépendances Python ──────────────────────────────────
info "Installation des dépendances Python..."
python3 -m pip install --break-system-packages -q \
    click \
    rich \
    Pillow \
    exifread \
    requests \
    ephem
ok "click, rich, Pillow, exifread, requests, ephem installés"

# ── 4. Copie du script ─────────────────────────────────────
info "Installation du script dans ${INSTALL_DIR}..."
if [[ ! -f "$SCRIPT_SRC" ]]; then
    error "Fichier '${SCRIPT_NAME}' introuvable dans le répertoire courant."
fi
cp "$SCRIPT_SRC" "${INSTALL_DIR}/${SCRIPT_NAME}"
chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
ok "Script installé → ${INSTALL_DIR}/${SCRIPT_NAME}"

# ── 5. Vérification finale ─────────────────────────────────
info "Test de la commande..."
if osint-geolocate --help &>/dev/null; then
    ok "Commande opérationnelle"
else
    error "Problème lors du test final."
fi

# ── 6. Ollama (optionnel) ──────────────────────────────────
echo
if command -v ollama &>/dev/null; then
    ok "Ollama détecté : $(ollama --version 2>/dev/null || echo 'installé')"
    info "Vérification des modèles vision..."
    MODELS=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)
    HAS_VISION=false
    for m in $MODELS; do
        case "$m" in
            *llava*|*llama3.2-vision*|*moondream*|*minicpm*)
                ok "Modèle vision trouvé : $m"
                HAS_VISION=true
                ;;
        esac
    done
    if [[ "$HAS_VISION" == false ]]; then
        warn "Aucun modèle vision trouvé."
        echo -e "       ${YELLOW}Installez-en un :${RESET}"
        echo -e "         ollama pull llava"
        echo -e "         ollama pull llama3.2-vision"
    fi
else
    warn "Ollama non installé (nécessaire pour le mode local)."
    echo -e "       ${YELLOW}Installation :${RESET} https://ollama.com/download"
    echo -e "       ${YELLOW}Puis :${RESET}         ollama pull llava"
fi

# ── Résumé ─────────────────────────────────────────────────
echo
echo -e "${BOLD}────────────────────────────────────────${RESET}"
echo -e "${GREEN}${BOLD} Installation terminée !${RESET}"
echo -e "${BOLD}────────────────────────────────────────${RESET}"
echo
echo -e "  ${BOLD}Mode local  :${RESET}  osint-geolocate photo.jpg"
echo -e "  ${BOLD}Mode cloud  :${RESET}  osint-geolocate photo.jpg --cloud --gemini-key YOUR_KEY"
echo -e "  ${BOLD}Aide        :${RESET}  osint-geolocate --help"
echo
