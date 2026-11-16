# Chapitre 4 : Les bases de données clé-valeur (Redis)

## 1. Prérequis

- Docker Desktop, démarré,
- le serveur PostgreSQL du chapitre 2, pour l’étude de cas de la section 4.7,
- Python 3.12 ou plus récent, pour les programmes de l’étude de cas.

Les commandes du chapitre ont été vérifiées avec Redis 8.10.2 ; le dépôt utilise l’image redis:8.10 et Redis Insight.

## 2. Installer

Depuis Redis 8, l’image officielle redis contient aussi le stockage de documents JSON et le moteur de requêtes, qui étaient auparavant distribués dans l’image redis-stack. Le fichier compose.yaml du dossier ch04-redis démarre le serveur, nommé redis, sur le port 6379, et l’outil graphique Redis Insight sur le port 5540 :
```
cd bd-modernes/ch04-redis
docker compose up -d
docker exec -it redis redis-cli
```
Sans le dépôt, les commandes suivantes démarrent les mêmes conteneurs :
```
docker run -d --name redis -p 6379:6379 redis:8.10
docker run -d --name redisinsight -p 5540:5540 \
       redis/redisinsight:latest
```

## 3. Autres méthodes d’installation

- **macOS** : `brew install redis`, puis `brew services start redis`,
- **Linux (Ubuntu)** : le dépôt APT de Redis (packages.redis.io), puis `sudo apt install redis`,
- **Windows** : Redis n’est pas offert en version native ; utilisez Docker Desktop ou une distribution Linux sous WSL 2.

## 4. Vérifier l’installation

Le serveur doit répondre PONG, et la commande JSON.SET doit réussir, ce qui confirme la présence du module JSON :
```
docker exec -it redis redis-cli PING
docker exec -it redis redis-cli JSON.SET essai '$' '{"ok":1}'
```
Résultat attendu :
```
PONG
OK
```
Redis Insight est ensuite accessible à l’adresse http://localhost:5540 ; ajoutez une base dont l’hôte est redis et le port 6379.

## 5. Charger les données

Les commandes des sections 4.4 et 4.5 créent elles-mêmes leurs clés. L’étude de cas de la section 4.7 lit la base club du chapitre 2 : démarrez aussi le conteneur pg-club, puis installez les dépendances Python du dossier :
```
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## 6. En cas de problème

- **le port 6379 est déjà utilisé** par un Redis installé sur le poste : arrêtez-le, ou changez le port dans compose.yaml,
- **JSON.SET retourne « unknown command »** : l’image utilisée est antérieure à Redis 8 ; utilisez redis:8.10,
- **Redis Insight ne trouve pas le serveur** : l’hôte est redis, le nom du service, et non localhost.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker exec -it redis redis-cli FLUSHALL   # vide la base
docker compose down
```
Redis conserve ses données en mémoire : sans persistance (section 4.5), elles disparaissent à l’arrêt du conteneur.
