# Chapitre 5 : Les bases de données orientées documents (MongoDB)

## 1. Prérequis

- Docker Desktop, démarré,
- Node.js 22 LTS ou plus récent, pour l’exemple Mongoose de la section 5.6,
- facultativement, l’outil graphique MongoDB Compass.

Les commandes du chapitre ont été vérifiées avec MongoDB 8.3, mongosh 2.14 et Mongoose 9 ; elles n’utilisent aucune fonction absente de MongoDB 9.0, l’image utilisée par le dépôt.

## 2. Installer

L’image officielle mongo contient le serveur et le shell mongosh. Le fichier compose.yaml du dossier ch05-mongodb démarre le serveur, nommé mongo, sur le port 27017 :
```
cd bd-modernes/ch05-mongodb
docker compose up -d
docker exec -it mongo mongosh
```
Sans le dépôt, la commande suivante démarre le même conteneur :
```
docker run -d --name mongo -p 27017:27017 mongo:9.0
```

## 3. Autres méthodes d’installation

- **macOS** : Homebrew, à partir du dépôt mongodb/brew (`brew install mongodb-community`),
- **Windows et Linux** : les installateurs de la page de téléchargement de mongodb.com, qui proposent aussi mongosh séparément.

L’outil graphique MongoDB Compass se connecte au serveur avec l’adresse mongodb://localhost:27017 (figure 5.2).

## 4. Vérifier l’installation

La commande suivante affiche la version du serveur :
```
docker exec -it mongo mongosh --quiet --eval "db.version()"
```
Résultat attendu :
```
9.0.4
```
Le dernier chiffre de la version peut différer.

## 5. Charger les données

Les bases de ce chapitre (employee, librairie et club) sont créées par les commandes du chapitre lui-même. Le fichier exemples_du_livre.md du dossier les reprend toutes, dans l’ordre, pour que vous puissiez les copier. Pour l’exemple Mongoose, installez les dépendances du dossier node :
```
cd node && npm install
```

## 6. En cas de problème

- **le port 27017 est déjà utilisé** par un MongoDB installé sur le poste : arrêtez-le, ou changez le port dans compose.yaml,
- **`mongosh` est introuvable** dans un terminal du poste : utilisez la forme `docker exec -it mongo mongosh`, ou installez mongosh,
- **les ObjectId ne correspondent pas à ceux du livre** : c’est normal, MongoDB les génère à chaque insertion.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker compose down -v
```
L’option -v supprime aussi le volume qui contient les bases.
