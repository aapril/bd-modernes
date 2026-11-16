# Chapitre 7 : Les bases de données graphes (Neo4j)

## 1. Prérequis

- Docker Desktop, démarré, ou Neo4j Desktop (section 7.3.2),
- les fichiers CSV du jeu de données de commerce électronique (section 7.3.5).

Le dépôt utilise l’image neo4j:2026-community et la bibliothèque APOC. Les requêtes Cypher du chapitre suivent la documentation de Neo4j 2026 ; le script verifier.sh du dossier permet de les contrôler sur votre poste.

## 2. Installer

Le fichier compose.yaml du dossier ch07-neo4j démarre le serveur, nommé neo4j, avec le mot de passe MotDePasse123 et la bibliothèque APOC. Il rend aussi le dossier import du dépôt visible par LOAD CSV :
```
cd bd-modernes/ch07-neo4j
docker compose up -d
```

## 3. Vérifier l’installation

La commande suivante exécute une requête avec l’outil cypher-shell du conteneur :
```
docker exec -it neo4j cypher-shell -u neo4j \
       -p MotDePasse123 --format plain \
       "RETURN 'Bonjour Neo4j !' AS message;"
```
Résultat attendu :
```
message
"Bonjour Neo4j !"
```
Neo4j Browser est accessible à l’adresse http://localhost:7474 (section 7.3.4).

## 4. Charger les données

Le graphe de commerce électronique de l’étude de cas TechMarket est chargé à partir des fichiers CSV du jeu de données public Olist. Ces fichiers et le script de chargement se trouvent dans deux dépôts du cours. Copiez les fichiers CSV dans le dossier import, puis corrigez le fichier order_reviews.csv avec le programme clean_csv.py du cours : une barre oblique inverse placée devant un guillemet y interrompt la lecture du CSV. Exécutez ensuite le script de chargement en lui appliquant les corrections du fichier corriger_chargement.sed du dépôt compagnon. La première retire le préfixe :auto, propre à Neo4j Browser, que cypher-shell ne reconnaît pas. La seconde corrige l’identification des articles de commande : le numéro order_item_id recommence à 1 dans chaque commande, et seule la paire (order_id, order_item_id) identifie un article ; sans cette correction, le graphe ne contiendrait que 21 articles. Le chargement dure environ une minute :
```
git clone https://github.com/rodrigueNTprojects/tp_levelDB_IND500.git
git clone https://github.com/rodrigueNTprojects/Neo4j_projet.git
cp tp_levelDB_IND500/data/*.csv import/
(cd import && python3 ../Neo4j_projet/clean_csv.py)
sed -f corriger_chargement.sed \
      Neo4j_projet/script_chargement.cypher \
    | docker exec -i neo4j cypher-shell -u neo4j -p MotDePasse123
```

## 5. En cas de problème

- **LOAD CSV ne trouve pas le fichier** : le fichier doit se trouver dans le dossier import, et l’adresse s’écrit file:///nom.csv,
- **le chargement s’arrête sur order_reviews.csv (Characters after an ending quote in a CSV field)** : le fichier n’a pas été corrigé ; exécutez clean_csv.py, puis relancez le chargement, qui commence par vider la base,
- **le chargement manque de mémoire** : augmentez la mémoire allouée à Docker Desktop à au moins 4 Go,
- **le mot de passe est refusé** : il est fixé au premier démarrage ; supprimez le volume avec `docker compose down -v` pour en changer.

## 6. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker compose down -v
```
Avec Neo4j Desktop, arrêtez l’instance dans l’application.
