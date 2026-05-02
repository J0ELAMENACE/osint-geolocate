# osint-geolocate

Outil CLI OSINT qui identifie la géolocalisation d'une image via un pipeline multi-modèles : EXIF, Picarta AI, vision LLM (3 passes), Nominatim, recherche web et calcul solaire.

Fait partie de la suite `osint-*`.

## Exemple de sortie

```
╔══════════════════════════════════════════════════════════════════╗
║  OSINT-GEOLOCATE v3  photo.jpg                                   ║
║  OCR:gemma4:31b-cloud  GEO:gemma4:31b-cloud  RAIS:gpt-oss:20b   ║
╚══════════════════════════════════════════════════════════════════╝

[EXIF     ]  Aucune donnee GPS

[PICARTA  ]  Top 1 : Boulogne-Billancourt, France (93%)
[PICARTA  ]  Coords : 48.83179, 2.25316

[OCR      ]  Texte  : 005300560052 // 14.1X
[OCR      ]  Langue : French

[GEO      ]  Trottoir  : Reddish-brown asphalt
[GEO      ]  Estimation: Boulogne-Billancourt, France

[FINAL    ]  Confiance : HIGH
[FINAL    ]  Preuves   : red pavement, French text, Picarta top 1

-> Boulogne-Billancourt, France
   48.83179 N,  2.25316 E

[MAPS       ]  https://maps.google.com/?q=48.831790,2.253160
[OSM        ]  https://www.openstreetmap.org/?mlat=48.831790&mlon=2.253160
[STREET VIEW]  https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=48.831790,2.253160
[YANDEX     ]  https://yandex.com/images/search?rpt=imageview
```

## Installation

```bash
git clone https://github.com/J0ELAMENACE/osint-geolocate
cd osint-geolocate
sudo bash install.sh
```

## Prérequis

- Linux (testé sur Kali 2024)
- Python 3.10+
- [Ollama](https://ollama.com) avec un compte connecté
- Clé API Picarta gratuite (optionnelle) : [picarta.ai](https://picarta.ai)

### Modèles Ollama

```bash
ollama pull gemma4:31b-cloud   # vision + OCR + geo (gratuit)
ollama pull gpt-oss:20b-cloud  # raisonnement (gratuit)
```

### Variable d'environnement

```bash
export PICARTA_API_KEY="votre_cle"  # gratuit sur picarta.ai
```

## Usage

```bash
# Standard
osint-geolocate photo.jpg

# Avec clé Picarta
osint-geolocate photo.jpg --picarta-key YOUR_KEY

# Via variable d'environnement
PICARTA_API_KEY=xxx osint-geolocate photo.jpg

# Options
osint-geolocate photo.jpg --no-solar     # sans calcul solaire
osint-geolocate photo.jpg --no-search    # sans recherche DDG

# Forcer des modèles
osint-geolocate photo.jpg \
  --ocr-model gemma4:31b-cloud \
  --geo-model gemma4:31b-cloud \
  --reas-model gpt-oss:20b-cloud
```

## Pipeline

```
photo.jpg
    │
    ├─[EXIF]       GPS present ? → résultat immédiat
    │
    ├─[PICARTA]    API spécialisée géolocalisation image
    │              top 5 candidats + coords + confiance
    │              relance avec hint France si scores faibles
    │
    ├─[PASSE OCR]  gemma4:31b-cloud
    │              lecture texte, codes, panneaux, langue
    │
    ├─[PASSE GEO]  gemma4:31b-cloud
    │              landmarks, architecture, infrastructure,
    │              trottoir, mobilier urbain, drapeaux
    │
    ├─[DDG]        Recherche web sur texte visible
    │
    ├─[NOMINATIM]  Geocodage OSM
    │
    ├─[PASSE RAIS] gpt-oss:20b-cloud
    │              cross-check OCR + GEO + Picarta + Web
    │              positions candidates avec confiance
    │
    ├─[SOLAR]      Validation ombre/soleil (si timestamp EXIF)
    │
    └─[OUTPUT]     Position + Google Maps + OSM + Street View + Yandex
```

## Stack

| Composant | Outil |
|-----------|-------|
| CLI | `click` |
| Output | `rich` |
| EXIF | `Pillow` |
| Solaire | `ephem` |
| Géolocalisation IA | [Picarta API](https://picarta.ai) |
| Vision / OCR / GEO | `gemma4:31b-cloud` via Ollama |
| Raisonnement | `gpt-oss:20b-cloud` via Ollama |
| Geocodage | Nominatim (OSM) |
| Recherche web | `ddgs` |

## Licence

CC BY-NC 4.0 — Copyright (c) 2026 J0ELAMENACE
