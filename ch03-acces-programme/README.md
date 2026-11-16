# Chapitre 3 : Accéder à une BD à partir d’un programme

## 1. Prérequis

- le serveur PostgreSQL du chapitre 2 (dossier ch02-postgresql), démarré,
- pour Java (sections 3.4 et 3.11) : un JDK 21 et Maven 3.9, ou un environnement comme IntelliJ IDEA qui les fournit,
- pour Python (section 3.6) : Python 3.12 ou plus récent,
- pour Node.js (sections 3.7 et 3.8) : Node.js 22 LTS ou plus récent,
- pour ODBC (section 3.5) : le pilote psqlODBC, offert par le projet PostgreSQL pour Windows, macOS et Linux.

Les exemples JDBC et Python ont été vérifiés avec PostgreSQL 16, pgJDBC 42.7 et psycopg 3 ; les exemples Prisma, Spring Data JPA, Django, Testcontainers et ODBC suivent la documentation officielle de ces outils.

## 2. Installer

Ce chapitre n’ajoute aucun serveur : il utilise le conteneur pg-club du chapitre 2. Le dossier ch03-acces-programme du dépôt contient un projet Maven (java/pom.xml), les dépendances Python (python/requirements.txt) et Node.js (node/package.json), ainsi que les fichiers de données. Installez les dépendances une fois :
```
cd bd-modernes/ch03-acces-programme
(cd java && mvn -q dependency:resolve)
python3 -m venv .venv && source .venv/bin/activate
pip install -r python/requirements.txt
(cd node && npm install)
```
Sous Windows, activez l’environnement virtuel Python avec .venv\Scripts\activate.

## 3. Autres méthodes d’installation

- **JDK** : Eclipse Temurin (adoptium.net) pour Windows, macOS et Linux, ou `brew install openjdk@21` sous macOS,
- **Maven** : maven.apache.org, ou `brew install maven` et `sudo apt install maven`,
- **psqlODBC** : l’installateur de postgresql.org pour Windows, `brew install psqlodbc` sous macOS et `sudo apt install odbc-postgresql` sous Ubuntu.

## 4. Vérifier l’installation

Le programme python/verifier.py se connecte à la base club et affiche la version du serveur et le nombre de membres :
```
python python/verifier.py
```
Résultat attendu :
```
Connexion réussie : PostgreSQL 18.1
Membres : 31
Fichiers de données : vins.csv, Films.json, clients_utf8.xml, films_utf8.xml, personnes_utf8.xml, nouveaux.csv
```
Le numéro de version exact du serveur peut différer. Pour Java, la commande `mvn -q compile` du dossier java doit se terminer sans erreur.

## 5. Charger les données

Les fichiers de la section 3.10 et de l’étude de cas sont dans le dossier donnees : vins.csv, Films.json, clients_utf8.xml, films_utf8.xml, personnes_utf8.xml et nouveaux.csv (exercice 3.6). Le fichier compose.yaml du chapitre 2 rend ce dossier visible dans le conteneur pg-club sous le chemin /donnees ; c’est ce chemin qu’utilisent les commandes COPY et pg_read_file du chapitre.
```
docker exec -it pg-club ls /donnees
```

## 6. En cas de problème

- **`mvn` ou `java` est introuvable** : vérifiez que le dossier bin du JDK et de Maven figure dans la variable PATH, puis ouvrez un nouveau terminal,
- **COPY ne trouve pas le fichier** : le chemin est celui du serveur ; utilisez /donnees/vins.csv avec COPY, ou la méta-commande \copy de psql pour un fichier de votre poste,
- **psycopg ne s’installe pas** : installez la variante précompilée, `pip install "psycopg[binary,pool]"`.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
deactivate                 # quitte l’environnement Python
docker compose -f ../ch02-postgresql/compose.yaml stop
```
Les tables créées dans ce chapitre (vins, films, client) restent dans la base club ; le script du chapitre 2 remet la base dans son état initial.
