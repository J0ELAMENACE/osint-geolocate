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
git clone https://github.com/VOTRE_USER/osint-geolocate
cd osint-geolocate
sudo bash install.sh
```

## Prérequis

- Linux (testé sur Ubuntu 24.04)
- Python 3.10+
- **Mode local** : [Ollama](https://ollama.com) + un modèle vision
- **Mode cloud** : clé Gemini gratuite ([Google AI Studio](https://aistudio.google.com/apikey))

### Installer un modèle vision pour Ollama

```bash
ollama pull llava              # recommandé, léger
ollama pull llama3.2-vision    # meilleure précision
```

## Usage

```bash
# Mode local (Ollama) — défaut
osint-geolocate photo.jpg

# Mode cloud (Gemini 2.0 Flash — gratuit)
osint-geolocate photo.jpg --cloud --gemini-key YOUR_KEY

# Clé via variable d'environnement
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
    ├─[2] AI VISION ─── Ollama local  (llava / llama3.2-vision)
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
| IA locale | Ollama (`localhost:11434`) |
| IA cloud | Gemini 2.0 Flash API |

## Variables d'environnement

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Clé API Google AI Studio (mode `--cloud`) |

## Licence

MIT
