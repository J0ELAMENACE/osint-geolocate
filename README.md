# osint-geolocate
Outil CLI OSINT qui tente d'identifier la géolocalisation d'une image en combinant analyse EXIF, vision par IA et calcul solaire. Sort un lien Google Maps en résultat final.
Fait partie de la suite `osint-*`.

## Exemple de sortie
```
╔══════════════════════════════════════════════════════╗
║  OSINT-GEOLOCATE  photo.jpg                          ║
╚══════════════════════════════════════════════════════╝
[EXIF   ]  Aucune donnée GPS trouvée
[VISUAL ]  Landmarks   : Tour Eiffel (97%), Champ-de-Mars (82%)
           Langue      : Français
           Architecture: Haussmannien
           Végétation  : Parcs urbains tempérés
           Climat      : Océanique tempéré
[SOLAR  ]  Soleil à 52.3° d'altitude, azimut 187.4°
╭─────────────────────────────────────────╮
│  → Paris, France                        │
│     48.8584° N,  2.2945° E             │
╰─────────────────────────────────────────╯
[MAPS]  https://maps.google.com/?q=48.858400,2.294500
```

## Installation
```bash
git clone https://github.com/J0ELAMENACE/osint-geolocate
cd osint-geolocate
sudo bash install.sh
```

## Prérequis
- Linux (testé sur Kali Linux / Ubuntu 24.04)
- Python 3.10+
- [Ollama](https://ollama.com) (installé automatiquement par `install.sh`)

## Modes IA

### Mode Ollama cloud — défaut recommandé ✅
Aucun GPU requis. Utilise `gemma4:31b-cloud` via l'API cloud Ollama.

> ⚠️ Nécessite un compte gratuit sur [ollama.com](https://ollama.com) et une authentification :
> ```bash
> ollama auth login
> ```

### Mode Ollama local — GPU requis
```bash
ollama pull llava              # léger (~4 GB)
ollama pull llama3.2-vision    # meilleure précision
```
Le script détecte automatiquement les modèles locaux installés.

### Mode Gemini cloud — clé API requise
Clé gratuite sur [Google AI Studio](https://aistudio.google.com/apikey).

## Usage
```bash
# Mode cloud Ollama (défaut — gemma4:31b-cloud)
osint-geolocate photo.jpg

# Forcer un modèle Ollama spécifique
osint-geolocate photo.jpg --model gemma4:31b-cloud
osint-geolocate photo.jpg --model llava

# Mode Gemini 2.0 Flash
osint-geolocate photo.jpg --cloud --gemini-key YOUR_KEY

# Clé Gemini via variable d'environnement
export GEMINI_API_KEY="AIza..."
osint-geolocate photo.jpg --cloud

# Sans calcul solaire
osint-geolocate photo.jpg --no-solar

# Aide
osint-geolocate --help
```

## Flow interne
```
photo.jpg
    │
    ├─[1] EXIF ──── GPS présent ? ──→ résultat immédiat
    │                    │
    │                    ✗
    ├─[2] AI VISION ─── Ollama cloud (gemma4:31b-cloud) ← défaut
    │                    OU Ollama local (llava / llama3.2-vision)
    │                    OU Gemini 2.0 Flash (--cloud)
    │                    → landmarks, langue, architecture,
    │                      végétation, signalisation, coordonnées
    │
    ├─[3] SOLAR ──── timestamp + coords disponibles ?
    │                    → validation altitude/azimut solaire
    │
    └─[4] OUTPUT ─── Rich terminal + lien Google Maps
```

## Stack
| Composant | Librairie |
|-----------|-----------|
| CLI | `click` |
| Output coloré | `rich` |
| EXIF / GPS | `Pillow`, `exifread` |
| Requêtes HTTP | `requests` |
| Calcul solaire | `ephem` |
| IA locale/cloud | Ollama (`localhost:11434`) |
| IA cloud alt. | Gemini 2.0 Flash API |

## Variables d'environnement
| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Clé API Google AI Studio (mode `--cloud`) |

## Licence
MIT
