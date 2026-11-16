# Chapitre 6 : Les bases de données de séries temporelles (TimescaleDB)

## 1. Prérequis

- Docker Desktop, démarré,
- aucun client psql n’est nécessaire sur le poste : celui du conteneur suffit.

Les commandes du chapitre ont été vérifiées avec PostgreSQL 16 et TimescaleDB 2.23 ; le dépôt utilise l’image timescale/timescaledb-ha:pg18, qui contient TimescaleDB 2.30 et la boîte à outils TimescaleDB Toolkit.

## 2. Installer

L’extension TimescaleDB s’installe sur un serveur PostgreSQL existant, mais l’image timescaledb-ha de Tiger Data contient déjà PostgreSQL 18, l’extension et la boîte à outils TimescaleDB Toolkit, utilisée à la section 6.5.5. Le conteneur, nommé timescaledb, utilise le port 5433 pour ne pas entrer en conflit avec le serveur du chapitre 2. Au premier démarrage, il crée la base bourse et ses deux extensions :
```
cd bd-modernes/ch06-timescaledb
docker compose up -d
docker exec -it timescaledb psql -U postgres -d bourse
```
Sans le dépôt, démarrez le conteneur, puis créez vous-même la base et les extensions :
```
docker run -d --name timescaledb -p 5433:5432 \
      -e POSTGRES_PASSWORD=MotDePasse123 \
      timescale/timescaledb-ha:pg18
docker exec -it timescaledb psql -U postgres
postgres=# CREATE DATABASE bourse;
postgres=# \c bourse
bourse=# CREATE EXTENSION IF NOT EXISTS timescaledb;
bourse=# CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
```

## 3. Autres méthodes d’installation

- **Linux** : les paquets de Tiger Data pour Debian, Ubuntu et Red Hat, ajoutés à un PostgreSQL existant,
- **macOS** : `brew install timescaledb`, à partir du dépôt timescale/tap,
- **Windows** : l’archive de Tiger Data pour un PostgreSQL installé avec l’installateur de EDB.

Avec une installation native, ajoutez timescaledb au paramètre shared_preload_libraries de postgresql.conf, puis redémarrez le serveur.

## 4. Vérifier l’installation

La requête suivante affiche la version de l’extension installée dans la base bourse :
```
docker exec -it timescaledb psql -U postgres -d bourse \
    -c "SELECT extversion FROM pg_extension WHERE extname = 'timescaledb';"
```
Résultat attendu :
```
 extversion
------------
 2.30.0
(1 row)
```
Le numéro de version peut être plus récent.

## 5. Charger les données

Le chapitre génère lui-même ses cotations boursières fictives (section 6.4). Pour passer directement à la section 6.5, exécutez le script donnees/cours.sql, qui crée l’hypertable cours et y insère les 129 603 cotations :
```
docker exec -i timescaledb psql -U postgres -d bourse \
       < donnees/cours.sql
```

## 6. En cas de problème

- **psql répond « connection refused » sur le port 5433** : le conteneur démarre encore ; attendez quelques secondes, puis réessayez,
- **la fonction lttb est inconnue** : l’extension timescaledb_toolkit n’est pas créée dans la base bourse,
- **les résultats diffèrent de ceux du livre** : les cotations sont aléatoires et datées des 30 derniers jours ; seules leur forme et leur nombre sont reproductibles.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker compose down -v
```
