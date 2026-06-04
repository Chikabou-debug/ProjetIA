# EcoTri AI

Projet de tri intelligent des dechets avec :

- une API Flask dans `api.py`
- un modele TensorFlow/Keras stocke localement dans `models/`
- une base MySQL `waste_db`
- une application Flutter dans `waste_sorter_app/`

## Important pour les collaborateurs

Les images lourdes, datasets, uploads et modeles entraines ne sont pas versionnes dans Git.
Ils doivent etre partages separement, par exemple avec Google Drive, OneDrive ou une GitHub Release.

Le fichier attendu par defaut est :

```text
models/best_model_b3_20260512_002223.keras
```

Si le modele a un autre nom ou un autre emplacement, configurer :

```powershell
$env:ECOTRI_MODEL_PATH="C:\chemin\vers\modele.keras"
```

## Installation backend

```powershell
git clone https://github.com/Chikabou-debug/ProjetIA.git
cd ProjetIA
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Base de donnees

Importer le schema MySQL :

```powershell
mysql -u root -p < database_schema.sql
```

Si MySQL n'a pas de mot de passe root, appuyer simplement sur Entree quand le mot de passe est demande.

## Lancer l'API

Mettre le modele partage dans `models/`, puis lancer :

```powershell
python api.py
```

Verifier l'API :

```text
http://localhost:5000/health
```

## Lancer l'application Flutter

Dans un autre terminal :

```powershell
cd waste_sorter_app
flutter pub get
flutter run
```

Dans l'application, ouvrir les parametres et mettre l'URL du serveur Flask.

Exemples :

- emulateur Android : `http://10.0.2.2:5000`
- telephone physique sur le meme Wi-Fi : `http://ADRESSE_IP_DU_PC:5000`
- navigateur/desktop sur le meme PC : `http://localhost:5000`

La cle API par defaut est `ecotri-demo-key`.

Pour utiliser une autre cle cote Flutter :

```powershell
flutter run --dart-define=ECOTRI_API_KEY=ma-cle
```
