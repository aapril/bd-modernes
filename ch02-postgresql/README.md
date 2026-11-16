# Chapitre 2 : La BD relationnelle et le langage SQL (PostgreSQL)

## 1. Prérequis

- Docker Desktop, installé et démarré, comme l’explique la section « Environnement de travail » de l’avant-propos,
- le dépôt compagnon du livre, cloné ou téléchargé sur votre poste,
- un navigateur Web, pour l’outil graphique pgAdmin 4.

Les requêtes du chapitre ont été vérifiées avec PostgreSQL 16.15 ; le dépôt utilise l’image postgres:18, la version la plus récente, et l’image dpage/pgadmin4.

## 2. Installer

Le dossier ch02-postgresql du dépôt contient un fichier compose.yaml qui démarre deux conteneurs : le serveur PostgreSQL, nommé pg-club, sur le port 5432, et pgAdmin 4, sur le port 5050. Placez-vous dans ce dossier, puis démarrez-les :
```
cd bd-modernes/ch02-postgresql
docker compose up -d
```
Sans le dépôt, la commande suivante démarre le même serveur, mais sans les données :
```
docker run -d --name pg-club -p 5432:5432 \
       -e POSTGRES_PASSWORD=MotDePasse123 postgres:18
```

## 3. Autres méthodes d’installation

- **Windows** : l’installateur de EDB (enterprisedb.com/downloads) installe le serveur, psql et pgAdmin,
- **macOS** : Postgres.app, ou Homebrew avec `brew install postgresql@18`,
- **Linux (Ubuntu)** : le dépôt APT de PostgreSQL (apt.postgresql.org), puis `sudo apt install postgresql-18`.

Avec une installation native, exécutez vous-même le script de chargement présenté plus bas.

## 4. Vérifier l’installation

La commande suivante interroge la base club dans le conteneur ; elle doit compter 4 044 réservations :
```
docker exec -it pg-club psql -U postgres -d club \
       -c "SELECT count(*) FROM réservations;"
```
Résultat attendu :
```
 count
-------
  4044
(1 row)
```
Le script verifier.sh du dossier exécute ensuite les requêtes des figures du chapitre et compare chaque résultat à celui du livre ; il doit afficher « 26 vérifications réussies, 0 écarts ». Pour pgAdmin, ouvrez http://localhost:5050, connectez-vous avec etudiant@exemple.com et MotDePasse123, puis enregistrez un serveur dont l’hôte est postgres (le nom du service), l’utilisateur postgres et le mot de passe MotDePasse123.

## 5. Charger les données

Au premier démarrage, le conteneur exécute le script donnees/01_club_sportif.sql, qui crée la base club et y charge les 31 membres, les 9 activités et les 4 044 réservations du Club Sportif, de juillet à septembre 2023. Pour remettre la base dans son état initial, par exemple après les mises à jour de la section 2.5, relancez le script :
```
docker exec -i pg-club psql -U postgres \
       < donnees/01_club_sportif.sql
```

## 6. En cas de problème

- **le port 5432 est déjà utilisé**, souvent par un PostgreSQL installé sur le poste : arrêtez ce serveur, ou remplacez "5432:5432" par "5434:5432" dans compose.yaml et utilisez le port 5434,
- **la base club n’existe pas** : le script ne s’exécute qu’à la création du volume ; supprimez le volume avec `docker compose down -v`, puis redémarrez,
- **pgAdmin refuse la connexion à localhost** : dans pgAdmin, qui s’exécute lui-même dans un conteneur, l’hôte du serveur est postgres et non localhost.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker compose stop      # arrête, sans rien perdre
docker compose down -v   # supprime aussi les données
```
Les chapitres 3, 4, 10 et 11 réutilisent ce serveur : arrêtez-le plutôt que de le supprimer.
