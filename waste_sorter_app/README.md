# EcoTri AI

Application mobile Flutter pour un systeme intelligent de tri de dechets.

## Objectif

EcoTri AI permet de scanner un dechet avec un telephone, d'envoyer l'image a une API Flask, puis d'obtenir:

- la categorie detectee par le modele IA;
- le pourcentage de confiance;
- le conseil de tri;
- l'historique des scans;
- les statistiques stockees dans MySQL.

## Architecture

```text
Application Flutter
        |
        | HTTP / JSON
        v
API Flask Python
        |
        | Prediction
        v
Modele EfficientNetB3 (.keras)
        |
        | Historique / statistiques
        v
Base MySQL waste_db
```

Flutter ne se connecte pas directement a MySQL. Cette separation rend le projet plus propre, plus securise et plus facile a presenter.

## Ecrans de l'application

- `Scanner`: capture une image avec la camera ou la galerie, puis affiche le resultat IA.
- `Suivi`: affiche les derniers scans enregistres dans MySQL.
- `Analyse`: affiche le total par classe et la confiance moyenne.
- `Parametres`: permet de modifier l'adresse de l'API Flask.

## Lancer le backend

Depuis le dossier racine du projet:

```powershell
$env:ECOTRI_API_KEY="ma-cle-secrete"
python api.py
```

L'API doit afficher une adresse proche de:

```text
http://192.168.43.74:5000
```

## Lancer l'application

Depuis le dossier `waste_sorter_app`:

```powershell
flutter run --dart-define=ECOTRI_API_KEY=ma-cle-secrete
```

La valeur de `ECOTRI_API_KEY` doit etre la meme dans le backend Flask et dans
l'application Flutter. Sinon, les routes protegees renverront une erreur
`401 Cle API manquante ou invalide`.

## Adresse API

Dans l'application, ouvrir les parametres avec l'icone en haut a droite, puis renseigner:

```text
http://ADRESSE_IP_DU_PC:5000
```

Exemple:

```text
http://192.168.43.74:5000
```

Pour trouver l'adresse IP du PC:

```powershell
ipconfig
```

Le telephone et le PC doivent etre sur le meme reseau.

## Verification rapide pour la soutenance

1. Demarrer XAMPP et MySQL.
2. Lancer `python api.py`.
3. Verifier que le telephone et le PC sont sur le meme reseau.
4. Lancer l'application Flutter.
5. Dans les parametres, enregistrer l'adresse API.
6. Scanner un dechet.
7. Montrer le resultat, le suivi et les statistiques.
