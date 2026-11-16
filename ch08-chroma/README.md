# Chapitre 8 : Les bases de données vectorielles (Chroma)

## 1. Prérequis

- Python 3.12 ou plus récent,
- une connexion Internet, pour télécharger les modèles de plongement et interroger Données Québec (section 8.5),
- environ 2 Go d’espace disque pour le modèle de sentence-transformers.

Les exemples ont été vérifiés avec Python 3.13 et Chroma 1.5.9 ; les programmes des figures 8.4 et 8.5 ont aussi été exécutés sur macOS.

## 2. Installer

Chroma s’exécute ici dans le programme Python, sans serveur. Le dossier ch08-chroma du dépôt contient le fichier requirements.txt ; créez un environnement virtuel et installez-y les bibliothèques :
```
cd bd-modernes/ch08-chroma
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```
Sous Windows, activez l’environnement avec .venv\Scripts\activate. Sans le dépôt, la commande suivante suffit :
```
pip install chromadb sentence-transformers
```

## 3. Autres méthodes d’installation

- **serveur Chroma** : pour partager une base entre plusieurs programmes, Chroma peut aussi s’exécuter comme serveur, avec `chroma run --path ./donnees` ou l’image Docker chromadb/chroma,
- **Anaconda** : les mêmes paquets s’installent dans un environnement conda.

## 4. Vérifier l’installation

La commande suivante affiche la version de Chroma :
```
python -c "import chromadb; print(chromadb.__version__)"
```
Résultat attendu :
```
1.5.9
```

## 5. Charger les données

Les données de la section 8.4 sont créées par le code du chapitre. L’étude de cas de la section 8.5 interroge l’API de Données Québec ; les programmes des figures 8.4 et 8.5 sont dans le dossier du dépôt :
```
python figure_8_4.py
python figure_8_5.py
```

## 6. En cas de problème

- **le premier lancement est long** : Chroma et sentence-transformers téléchargent leurs modèles ; les lancements suivants les réutilisent,
- **les résultats de la section 8.5 diffèrent du livre** : le catalogue de Données Québec change avec le temps ; seules la forme et la pertinence des réponses sont comparables,
- **pip échoue sur onnxruntime ou torch** : utilisez une version de Python prise en charge par ces bibliothèques, par exemple 3.12.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
deactivate
rm -rf .venv vectordb
```
Sous Windows, supprimez ces deux dossiers avec l’explorateur de fichiers.
