# Les bases de données modernes : dépôt compagnon

Ce dépôt accompagne le livre *Les bases de données modernes* (Alain April et Mathieu Dupuis, Édition Smart, 2026).
Il contient, pour chaque chapitre pratique, les fichiers nécessaires pour installer la technologie, charger les données et vérifier vos résultats sans aide extérieure.

## Obtenir le dépôt

```
git clone https://github.com/aapril/bd-modernes.git
cd bd-modernes
```

Sans Git, téléchargez l’archive ZIP à partir de la page du dépôt (bouton **Code**, puis **Download ZIP**) et décompressez-la.

## Prérequis communs

- **Docker Desktop** (Windows 10 ou 11 avec WSL 2, macOS 13 ou plus récent, puces Intel ou Apple) ou Docker Engine avec le module compose sous Linux. Réservez-lui au moins 4 Go de mémoire (8 Go pour les chapitres 7 et 12).
- **Git**, pour cloner ce dépôt et ceux des travaux pratiques.
- **Python 3.12** pour les chapitres 3, 4, 8, 10, 11 et 13 (3.12 plutôt que 3.13 : plyvel, au chapitre 13, n’est offert précompilé que pour 3.12 sous Linux).
- **Un JDK 21 et Maven 3.9** pour les chapitres 3, 9 (JDK 17) et 12.
- **Node.js 22 LTS** pour les chapitres 3 et 5.
- Sous Windows, les scripts `verifier.sh` s’exécutent dans un terminal Ubuntu sous WSL 2 ou dans Git Bash.

## Conventions

Tous les serveurs utilisent l’utilisateur administrateur indiqué dans le livre et le mot de passe **MotDePasse123** (MinIO : minioadmin / minioadmin).
Arrêtez les conteneurs d’un chapitre (`docker compose stop`) avant de passer au suivant : plusieurs chapitres utilisent des ports voisins.

| Chapitre | Dossier | Conteneurs | Ports |
|---|---|---|---|
| 2, 3, 4, 10, 11 | ch02-postgresql | pg-club, pgadmin | 5432, 5050 |
| 4 | ch04-redis | redis, redisinsight | 6379, 5540 |
| 5 | ch05-mongodb | mongo | 27017 |
| 6 | ch06-timescaledb | timescaledb | 5433 |
| 7 | ch07-neo4j | neo4j | 7474, 7687 |
| 9 | ch09-hbase | (installation locale) | 16010 |
| 10 | ch10-dagster | citus (section 10.5.2) | 3000, 5435 |
| 11 | ch11-lac-de-donnees | minio | 9000, 9001 |
| 12 | ch12-kafka | kafka | 9092 |
| 13 | ch13-registre | couchdb | 5984 |

## Organisation de chaque dossier

Chaque dossier `chNN-…` contient un `README.md` qui suit toujours les mêmes sept étapes que la section d’installation du chapitre :
prérequis, installation, autres méthodes, vérification, chargement des données, problèmes fréquents, arrêt et nettoyage.
Il contient aussi `exemples_du_livre.md`, qui reprend tous les blocs de code du chapitre dans l’ordre, pour que vous puissiez les copier.

## Licences des données

- Club Sportif (chapitres 2, 3, 4, 10, 11) : adapté de PostgreSQL Exercises d’Alisdair Owens, données sous licence de type BSD.
- Commerce électronique (chapitres 7 et 13) : jeu de données public Olist, distribué par ses auteurs sur Kaggle sous licence CC BY-NC-SA 4.0.
- Données de l’étude de cas du chapitre 3 (clients, films, personnes) : les clients sont fictifs, générés pour le laboratoire du cours.

## Licence du code

Le code et les scripts de ce dépôt sont distribués sous licence MIT (fichier `LICENSE`). Les données et les dépôts externes conservent leurs propres licences.
