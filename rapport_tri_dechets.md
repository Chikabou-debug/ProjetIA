# Rapport de projet : EcoTri AI

## Système intelligent de tri de déchets

**Nom et prénom :** CHIKABOU JACQUES ET EVINA ZENGUE JAPHET........................................  
**Classe / Filière :** ........................................  
**Enseignant :** ........................................  
**Année scolaire :** 2025 - 2026  

---

## 1. Introduction

Le tri des déchets est une action importante pour protéger l’environnement et faciliter le recyclage. Dans la vie quotidienne, plusieurs types de déchets sont produits : plastique, papier, métal et déchets organiques. Cependant, il n’est pas toujours facile de savoir dans quel bac déposer chaque déchet.

Dans ce projet, nous avons réalisé un système intelligent appelé **EcoTri AI**. Ce système permet de capturer l’image d’un déchet, de l’analyser avec un modèle d’intelligence artificielle, puis de donner la catégorie du déchet et le bac conseillé.

---

## 2. Problématique

La mauvaise classification des déchets peut provoquer des problèmes dans le processus de recyclage. Par exemple, un déchet organique placé dans un bac de recyclage peut contaminer les autres déchets recyclables.

La problématique de ce projet est donc la suivante :

**Comment développer une application capable d’identifier automatiquement le type d’un déchet à partir d’une image ?**

---

## 3. Objectifs du projet

L’objectif principal du projet est de créer un système de tri intelligent capable de reconnaître différents types de déchets.

Les objectifs spécifiques sont :

- Capturer une image de déchet avec une application mobile.
- Envoyer l’image vers une API de prédiction.
- Utiliser un modèle d’intelligence artificielle pour classifier le déchet.
- Afficher le résultat dans l’application mobile.
- Enregistrer les images capturées et les résultats dans une base de données.
- Afficher l’historique des classifications et des statistiques.

---

## 4. Technologies utilisées

| Technologie | Rôle dans le projet |
|---|---|
| Python | Développement du modèle IA et de l’API |
| TensorFlow / Keras | Entraînement et utilisation du modèle de classification |
| EfficientNetB3 | Architecture du modèle de deep learning |
| Flask | Création de l’API backend |
| MySQL | Sauvegarde des catégories et des résultats de classification |
| Flutter | Développement de l’application mobile |
| Dart | Langage utilisé avec Flutter |
| OpenCV | Test de classification avec la caméra |

---

## 5. Présentation générale du système

Le système EcoTri AI fonctionne selon les étapes suivantes :

1. L’utilisateur ouvre l’application mobile.
2. Il prend une photo d’un déchet ou choisit une image depuis la galerie.
3. L’image est envoyée à l’API Flask.
4. L’API prépare l’image et l’envoie au modèle EfficientNetB3.
5. Le modèle prédit la classe du déchet.
6. L’application affiche la catégorie, le pourcentage de confiance et le conseil de tri.
7. L’image et le résultat sont enregistrés dans l’historique.
8. Les statistiques sont calculées à partir des classifications enregistrées.

---

## 6. Architecture du projet

Le projet est composé de plusieurs parties :

| Fichier / dossier | Description |
|---|---|
| `train_model.py` | Script d’entraînement du modèle IA |
| `api.py` | API Flask utilisée pour recevoir les images et retourner les prédictions |
| `camera.py` | Test de prédiction en temps réel avec webcam |
| `database_schema.sql` | Script de création de la base de données MySQL |
| `waste_sorter_app/` | Application mobile Flutter |
| `uploads/scans/` | Dossier contenant les images de déchets capturées |
| `models/` | Dossier contenant le modèle entraîné et les graphiques de performance |

---

## 7. Dataset utilisé

Le dataset contient quatre catégories de déchets :

- Déchets organiques
- Métal
- Papier
- Plastique

### Nombre d’images par classe

| Classe | Nombre d’images |
|---|---:|
| Déchets organiques | 699 |
| Métal | 930 |
| Papier | 1336 |
| Plastique | 1597 |
| **Total** | **4562** |

### Répartition du dataset

Les images ont été divisées en trois parties :

| Partie du dataset | Nombre d’images |
|---|---:|
| Entraînement | 3192 |
| Validation | 682 |
| Test | 688 |

Cette répartition permet d’entraîner le modèle, de contrôler ses performances pendant l’apprentissage, puis de tester sa capacité à reconnaître de nouvelles images.

---

## 8. Entraînement du modèle

Pour la classification des déchets, nous avons utilisé un modèle de deep learning basé sur **EfficientNetB3**. Ce modèle est adapté à la classification d’images et permet d’obtenir de bonnes performances grâce au transfert d’apprentissage.

Le modèle a été entraîné en deux phases :

1. **Première phase :** entraînement des nouvelles couches ajoutées au modèle.
2. **Deuxième phase :** fine-tuning, c’est-à-dire ajustement d’une partie du modèle EfficientNetB3 pour améliorer la précision.

Pendant l’entraînement, des techniques d’augmentation des données ont été utilisées, comme la rotation, le zoom, le changement de luminosité et le retournement horizontal. Cela permet au modèle d’être plus robuste face aux variations des images capturées.

### Courbes d’apprentissage

L’image suivante montre l’évolution de la précision et de la perte pendant l’entraînement :

<img src="models/courbes_apprentissage_b3_20260512_002223.png" width="650">

### Matrice de confusion

La matrice de confusion permet de voir les bonnes et mauvaises prédictions du modèle sur les données de test :

<img src="models/confusion_matrix_b3_20260512_002223.png" width="500">

---

## 9. API Flask

L’API Flask constitue le lien entre l’application mobile et le modèle d’intelligence artificielle.

Les principales routes de l’API sont :

| Route | Rôle |
|---|---|
| `GET /health` | Vérifier si l’API et le modèle sont disponibles |
| `POST /predict` | Recevoir une image et retourner la prédiction |
| `GET /historique` | Afficher l’historique des déchets scannés |
| `GET /stats` | Afficher les statistiques des classifications |
| `DELETE /delete/<id>` | Supprimer un scan de l’historique |

Lorsqu’une image est reçue, elle est sauvegardée dans le dossier `uploads/scans`, puis elle est redimensionnée en `300 x 300` pixels avant d’être envoyée au modèle.

---

## 10. Base de données

La base de données utilisée est **MySQL**. Elle contient deux tables principales :

| Table | Description |
|---|---|
| `categories` | Contient les types de déchets, les conseils, la couleur et le bac conseillé |
| `classifications` | Contient les résultats des scans : catégorie, confiance, date et chemin de l’image |

La table `classifications` permet de conserver l’historique des déchets capturés par l’utilisateur.

---

## 11. Application mobile

L’application mobile est développée avec **Flutter**. Elle contient trois écrans principaux.

### Écran Scanner

Cet écran permet de prendre une photo d’un déchet avec la caméra ou de choisir une image depuis la galerie. Après l’analyse, l’application affiche :

- la catégorie du déchet ;
- le pourcentage de confiance ;
- le conseil de tri.

### Écran Historique

Cet écran affiche les déchets déjà scannés. Pour chaque scan, l’application montre :

- une miniature de l’image capturée ;
- la classe prédite ;
- la date du scan ;
- le pourcentage de confiance.

### Écran Statistiques

Cet écran affiche le nombre de scans par catégorie et la confiance moyenne du modèle.

---

## 12. Résultats obtenus avec les déchets capturés

Les images suivantes proviennent du dossier `uploads/scans`. Elles correspondent aux déchets capturés pendant les tests de l’application.

| N° | Image capturée | Classe prédite | Confiance | Bac conseillé |
|---:|---|---|---:|---|
| 1 | <img src="uploads/scans/scan_20260512_141038_a46a4ab3.jpg" width="160"> | Plastique | 89.72 % | Bac jaune |
| 2 | <img src="uploads/scans/scan_20260512_143244_05f298f3.jpg" width="160"> | Papier | 98.76 % | Bac bleu |
| 3 | <img src="uploads/scans/scan_20260512_143422_bf6a0cc8.jpg" width="160"> | Plastique | 100.00 % | Bac jaune |
| 4 | <img src="uploads/scans/scan_20260512_143511_3bd47c8c.jpg" width="160"> | Métal | 91.46 % | Bac jaune |
| 5 | <img src="uploads/scans/scan_20260512_144641_c07253c9.jpg" width="160"> | Papier | 100.00 % | Bac bleu |
| 6 | <img src="uploads/scans/scan_20260512_144715_2da024ba.jpg" width="160"> | Papier | 99.97 % | Bac bleu |
| 7 | <img src="uploads/scans/scan_20260517_054532_fdd1cff9.jpg" width="160"> | Plastique | 77.19 % | Bac jaune |
| 8 | <img src="uploads/scans/scan_20260517_065930_a0417783.jpg" width="160"> | Papier | 100.00 % | Bac bleu |
| 9 | <img src="uploads/scans/scan_20260517_073120_05279d4d.jpg" width="160"> | Métal | 99.83 % | Bac jaune |
| 10 | <img src="uploads/scans/scan_20260517_080306_e8229f0a.jpg" width="160"> | Papier | 83.26 % | Bac bleu |
| 11 | <img src="uploads/scans/scan_20260520_044407_72f6a0f5.jpg" width="160"> | Papier | 87.68 % | Bac bleu |

Ces résultats montrent que le système est capable de reconnaître plusieurs déchets avec un niveau de confiance généralement élevé. Certaines prédictions ont une confiance plus faible, par exemple 77.19 %, ce qui peut être dû à la qualité de l’image, à l’éclairage ou à la position du déchet.

---

## 13. Difficultés rencontrées

Pendant la réalisation du projet, plusieurs difficultés peuvent être rencontrées :

- Certaines images peuvent être floues ou mal éclairées.
- Les déchets peuvent être difficiles à reconnaître s’ils sont déformés ou partiellement visibles.
- Le modèle peut confondre certaines catégories lorsque les objets se ressemblent.
- La connexion entre l’application mobile et l’API Flask doit être correctement configurée.
- La base de données MySQL doit être lancée pour sauvegarder l’historique.

---

## 14. Améliorations possibles

Le projet peut être amélioré de plusieurs façons :

- Ajouter plus de catégories de déchets, comme le verre ou le carton.
- Augmenter le nombre d’images dans le dataset.
- Améliorer l’interface graphique de l’application.
- Ajouter une fonctionnalité de correction manuelle lorsque le modèle se trompe.
- Utiliser un modèle plus léger pour améliorer la vitesse sur mobile.
- Ajouter une vraie connexion avec un système mécanique de tri automatique.

---

## 15. Conclusion

Ce projet m’a permis de développer un système intelligent de tri de déchets basé sur l’intelligence artificielle. Le système EcoTri AI peut capturer une image, identifier le type de déchet et proposer le bac correspondant.

Le projet combine plusieurs technologies : Flutter pour l’application mobile, Flask pour l’API, TensorFlow pour le modèle IA et MySQL pour la sauvegarde des résultats. Les tests réalisés montrent que le système peut reconnaître les déchets avec une bonne précision, même si des améliorations restent possibles.

En conclusion, EcoTri AI est une solution intéressante pour sensibiliser au tri des déchets et montrer comment l’intelligence artificielle peut être utilisée dans le domaine de l’environnement.

