# Travail pratique de la section 12.8 : base de code fournie

Ce dossier contient la base de code du travail pratique :

- `docker-compose.yml` démarre le serveur Kafka du travail pratique (conteneur broker, port 9092), l’interface Web (http://localhost:8080) et les conteneurs qui produisent les événements (`order_generator`, `transporter_generator`) et répondent aux demandes de soumission (`shipping_listener`) ;
- `pom.xml` et `src/` forment le projet Java de départ (Kafka Streams, Java 17 ou plus récent), à ouvrir dans IntelliJ IDEA.

Arrêtez d’abord le serveur Kafka du chapitre (`docker compose stop` dans le dossier ch12-kafka), car les deux utilisent le port 9092. Puis, dans ce dossier :

```
docker compose up -d
```

L’image des générateurs n’existe que pour les processeurs Intel (amd64) : sur un Mac à puce Apple, le fichier docker-compose.yml la fait exécuter en émulation (`platform: linux/amd64`), ce qui demande l’option Rosetta de Docker Desktop (Settings, General).

Arrêtez les générateurs lorsque vous ne travaillez pas : ils remplissent peu à peu la mémoire du serveur. `docker compose down` supprime tout le système ; `docker compose up -d` le recrée avec de nouvelles données aléatoires.
