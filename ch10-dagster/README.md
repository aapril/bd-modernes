# Chapitre 10 : Gouvernance, orchestration de données et ETL (Dagster)

## 1. Prérequis

- Python 3.12 et uv, le gestionnaire de paquets recommandé par Dagster,
- Docker Desktop, pour le serveur PostgreSQL du chapitre 2 et, à la section 10.5.2, pour Citus,
- un éditeur de code, par exemple Visual Studio Code.

Les commandes ont été vérifiées avec Dagster 1.13.30 (novembre 2026).

## 2. Installer

Installez uv, puis créez le projet comme à la section 10.8.2 :
```
curl -LsSf https://astral.sh/uv/install.sh | sh
uvx create-dagster@latest project club-sportif
cd club-sportif && source .venv/bin/activate
uv add pandas sqlalchemy "psycopg[binary]" pyarrow
uv add --dev pytest
```
Sous Windows, installez uv dans PowerShell avec `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"`. Pour la section 10.5.2, le fichier compose.yaml de ce dossier démarre un serveur PostgreSQL avec l’extension Citus sur le port 5435 :
```
docker compose up -d citus
```

## 3. Vérifier l’installation

Dans le dossier du projet, les commandes suivantes affichent la version de Dagster, puis vérifient que les définitions se chargent sans erreur :
```
dg --version
dg check defs
```
Résultat attendu :
```
dg, version 1.13.30
All component YAML validated successfully.
All definitions loaded successfully.
```
Le numéro de version peut être plus récent. Lancez ensuite l’interface avec `dg dev` et ouvrez http://localhost:3000.

## 4. Charger les données

Les exemples utilisent le fichier vins.csv du chapitre 3 et la base club du chapitre 2. Copiez le fichier dans le dossier data du projet et démarrez le serveur PostgreSQL :
```
mkdir -p data
cp ../bd-modernes/ch03-acces-programme/donnees/vins.csv data/
docker compose -f ../bd-modernes/ch02-postgresql/compose.yaml up -d
```

## 5. En cas de problème

- **`dg` est introuvable** : activez l’environnement virtuel du projet (`source .venv/bin/activate`), ou préfixez les commandes de `uv run`,
- **un actif échoue avec une erreur de connexion** : le conteneur pg-club n’est pas démarré, ou la variable DATABASE_URL du fichier .env est incorrecte,
- **les conditions d’automatisation et les capteurs ne se déclenchent pas** : ils doivent être activés dans l’interface (onglet Automation).

## 6. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
# Ctrl+C arrête dg dev
rm -rf data/reservations     # résultats des partitions
```
