# Chapitre 12 : Les plateformes de diffusion de données en continu (Kafka)

## 1. Prérequis

- Docker Desktop, démarré, avec au moins 4 Go de mémoire,
- un JDK 21 et Maven 3.9, ou IntelliJ IDEA, pour les programmes Java des sections 12.4 et 12.5,
- le serveur PostgreSQL du chapitre 2, pour l’exemple d’insertion par lots de la section 12.4.

Le dépôt utilise l’image apache/kafka:4.4.0 et les bibliothèques kafka-clients et kafka-streams 4.4.0 ; les commandes du chapitre fonctionnent avec toutes les versions 4.x de Kafka.

## 2. Installer

L’image Docker officielle démarre un courtier unique en mode KRaft, suffisant pour les exercices. Le fichier compose.yaml du dossier ch12-kafka démarre le courtier, nommé kafka, sur le port 9092 :
```
cd bd-modernes/ch12-kafka
docker compose up -d
```
Sans le dépôt, la commande suivante démarre le même courtier :
```
docker run -d --name kafka -p 9092:9092 apache/kafka:4.4.0
```

## 3. Autres méthodes d’installation

- **archive binaire** : sous macOS et Linux, l’archive de kafka.apache.org/downloads s’exécute avec un JDK 17 ou plus récent (`bin/kafka-server-start.sh`) ; sous Windows, utilisez WSL 2,
- **Homebrew** : `brew install kafka` sous macOS.

## 4. Vérifier l’installation

La commande suivante liste les sujets du courtier ; sur un courtier neuf, la liste est vide et la commande se termine sans erreur :
```
docker exec -it kafka /opt/kafka/bin/kafka-topics.sh \
       --bootstrap-server localhost:9092 --list
```
Pour les programmes Java, la commande `mvn -q compile` du dossier java doit se terminer sans erreur ; le fichier pom.xml déclare les dépendances kafka-clients, kafka-streams et le pilote PostgreSQL.

## 5. Charger les données

Les sujets et les messages des sections 12.3 à 12.5 sont créés par les commandes et les programmes du chapitre. Le travail pratique de la section 12.8 utilise sa propre base de code, code.zip, qui contient son fichier docker-compose.yml et son générateur d’événements ; votre enseignant vous la remet, et le dossier tp du dépôt indique où la placer.
```
cd java && mvn -q compile
```

## 6. En cas de problème

- **le client ne joint pas le courtier** : l’adresse est localhost:9092 depuis le poste, mais kafka:9092 depuis un autre conteneur du même fichier compose,
- **le courtier s’arrête au démarrage** : Docker Desktop manque de mémoire ; allouez-lui au moins 4 Go,
- **Maven ne trouve pas les dépendances** : vérifiez la connexion au dépôt Maven Central, ou ouvrez le projet dans IntelliJ IDEA, qui les télécharge.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker compose down -v
```
Le travail pratique se nettoie de la même façon avec son propre fichier docker-compose.yml (section 12.8.4).
