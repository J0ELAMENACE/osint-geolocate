#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  osint-geolocate v3 — install script
#  Usage : sudo bash install.sh
# ─────────────────────────────────────────────────────────────

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()    { echo -e "${GREEN}[ OK ]${RESET}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error() { echo -e "${RED}[ERR ]${RESET}  $*"; exit 1; }

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="osint-geolocate"
SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)/${SCRIPT_NAME}"

echo
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   osint-geolocate v3  —  installer       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo

# ── 0. Root check ──────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
    error "Lancez avec sudo : sudo bash install.sh"
fi

# ── 1. Python 3 ────────────────────────────────────────────
info "Vérification Python 3..."
if ! command -v python3 &>/dev/null; then
    info "Installation de Python 3..."
    apt-get update -qq && apt-get install -y -qq python3 python3-pip
fi
ok "$(python3 --version)"

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
    requests \
    ephem \
    ddgs
ok "click, rich, Pillow, requests, ephem, ddgs installés"

# ddgs remplace duckduckgo_search
python3 -m pip uninstall -y duckduckgo_search 2>/dev/null || true

# ── 4. Curl (pour Ollama) ──────────────────────────────────
if ! command -v curl &>/dev/null; then
    info "Installation de curl..."
    apt-get install -y -qq curl
fi

# ── 5. Ollama ──────────────────────────────────────────────
echo
info "Vérification Ollama..."
if ! command -v ollama &>/dev/null; then
    info "Installation d'Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    ok "Ollama installé"
else
    ok "Ollama déjà installé : $(ollama --version 2>/dev/null || echo 'présent')"
fi

# Démarrer ollama serve en arrière-plan si pas actif
if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
    info "Démarrage d'Ollama en arrière-plan..."
    ollama serve &>/dev/null &
    sleep 3
fi

# ── 6. Modèles Ollama ──────────────────────────────────────
echo
info "Vérification des modèles Ollama cloud..."

pull_if_missing() {
    local model="$1"
    if ollama list 2>/dev/null | grep -q "${model%:*}"; then
        ok "Modèle déjà présent : $model"
    else
        info "Pull du modèle : $model"
        if ollama pull "$model" 2>&1; then
            ok "$model prêt"
        else
            warn "$model — échec du pull (compte Ollama requis ou modèle payant)"
        fi
    fi
}

pull_if_missing "gemma4:31b-cloud"
pull_if_missing "gpt-oss:20b-cloud"

# ── 7. Copie du script ─────────────────────────────────────
echo
info "Installation du script dans ${INSTALL_DIR}..."
if [[ ! -f "$SCRIPT_SRC" ]]; then
    error "Fichier '${SCRIPT_NAME}' introuvable dans le répertoire courant."
fi
cp "$SCRIPT_SRC" "${INSTALL_DIR}/${SCRIPT_NAME}"
chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
ok "Script installé → ${INSTALL_DIR}/${SCRIPT_NAME}"

# ── 8. Variable d'environnement Picarta ────────────────────
echo
SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q "PICARTA_API_KEY" "$SHELL_RC" 2>/dev/null; then
        warn "Clé Picarta non configurée."
        echo -e "       ${YELLOW}Ajoutez votre clé dans ${SHELL_RC} :${RESET}"
        echo -e "         export PICARTA_API_KEY=\"votre_cle\""
        echo -e "       ${YELLOW}Clé gratuite (10 crédits) :${RESET} https://picarta.ai"
    else
        ok "Clé Picarta déjà présente dans ${SHELL_RC}"
    fi
fi

# ── 9. Test final ──────────────────────────────────────────
echo
info "Test de la commande..."
if "${INSTALL_DIR}/${SCRIPT_NAME}" --help &>/dev/null; then
    ok "Commande opérationnelle"
else
    error "Problème lors du test final."
fi

# ── Résumé ─────────────────────────────────────────────────
echo
echo -e "${BOLD}──────────────────────────────────────────${RESET}"
echo -e "${GREEN}${BOLD} Installation terminée !${RESET}"
echo -e "${BOLD}──────────────────────────────────────────${RESET}"
echo
echo -e "  ${BOLD}Usage :${RESET}"
echo -e "    osint-geolocate photo.jpg"
echo -e "    osint-geolocate photo.jpg --picarta-key YOUR_KEY"
echo -e "    PICARTA_API_KEY=xxx osint-geolocate photo.jpg"
echo -e ""
echo -e "  ${BOLD}Modèles :${RESET}"
echo -e "    gemma4:31b-cloud  — vision / OCR / géo"
echo -e "    gpt-oss:20b-cloud — raisonnement"
echo -e ""
echo -e "  ${BOLD}Aide :${RESET}  osint-geolocate --help"
echo
