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

# ── 6. Ollama ──────────────────────────────────────────────
echo
echo -e "${BOLD}── Ollama ───────────────────────────────${RESET}"

if command -v ollama &>/dev/null; then
    ok "Ollama déjà installé : $(ollama --version 2>/dev/null || echo 'version inconnue')"
else
    warn "Ollama non trouvé — installation en cours..."
    if command -v curl &>/dev/null; then
        curl -fsSL https://ollama.com/install.sh | sh
        ok "Ollama installé"
    else
        warn "curl non disponible. Installez Ollama manuellement :"
        echo -e "       ${CYAN}https://ollama.com/download${RESET}"
    fi
fi

# ── 7. Démarrage du service Ollama ─────────────────────────
if command -v ollama &>/dev/null; then
    if ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
        info "Démarrage du service Ollama..."
        systemctl enable ollama 2>/dev/null || true
        systemctl start ollama 2>/dev/null || ollama serve &>/dev/null &
        sleep 2
    fi

    if curl -sf http://localhost:11434/api/tags &>/dev/null; then
        ok "Service Ollama actif sur localhost:11434"
    else
        warn "Service Ollama non accessible — lancez manuellement : ollama serve"
    fi

    # ── 8. Modèles locaux ──────────────────────────────────
    MODELS=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)
    HAS_VISION=false
    if [[ -n "$MODELS" ]]; then
        for m in $MODELS; do
            case "$m" in
                *llava*|*llama3.2-vision*|*moondream*|*minicpm*|*gemma4*)
                    ok "Modèle vision local trouvé : $m"
                    HAS_VISION=true
                    ;;
            esac
        done
    fi

    # ── 9. Info modèles cloud ──────────────────────────────
    echo
    echo -e "${BOLD}── Modèles cloud Ollama (recommandé) ───${RESET}"
    echo -e "  ${CYAN}Les modèles :cloud ne nécessitent pas de GPU${RESET}"
    echo -e "  ${YELLOW}⚠  Ils nécessitent un compte ollama.com${RESET}"
    echo
    echo -e "  ${BOLD}1. Créez un compte :${RESET} https://ollama.com"
    echo -e "  ${BOLD}2. Authentifiez-vous :${RESET}"
    echo -e "       ${CYAN}ollama auth login${RESET}"
    echo -e "  ${BOLD}3. Modèle utilisé par défaut :${RESET} gemma4:31b-cloud"
    echo -e "     (aucun pull nécessaire, accès direct via API cloud)"
    echo

    if [[ "$HAS_VISION" == false ]]; then
        info "Aucun modèle vision local — le mode cloud sera utilisé par défaut."
        echo -e "  Pour un modèle local (GPU requis) :"
        echo -e "       ${CYAN}ollama pull llava${RESET}"
        echo -e "       ${CYAN}ollama pull llama3.2-vision${RESET}"
    fi
fi

# ── Résumé ─────────────────────────────────────────────────
echo
echo -e "${BOLD}────────────────────────────────────────${RESET}"
echo -e "${GREEN}${BOLD} Installation terminée !${RESET}"
echo -e "${BOLD}────────────────────────────────────────${RESET}"
echo
echo -e "  ${BOLD}Mode cloud Ollama (défaut) :${RESET}"
echo -e "       osint-geolocate photo.jpg"
echo -e "       ${YELLOW}⚠ Requiert : ollama auth login${RESET}"
echo
echo -e "  ${BOLD}Modèle spécifique :${RESET}"
echo -e "       osint-geolocate photo.jpg --model gemma4:31b-cloud"
echo -e "       osint-geolocate photo.jpg --model llava"
echo
echo -e "  ${BOLD}Mode Gemini (clé API) :${RESET}"
echo -e "       osint-geolocate photo.jpg --cloud --gemini-key YOUR_KEY"
echo
echo -e "  ${BOLD}Aide :${RESET}"
echo -e "       osint-geolocate --help"
echo
