# Chapitre 7 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 7.1.2 Modèle de graphes vs modèle relationnel

> Schéma relationnel (SQL)

```
-- Table des utilisateurs
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);
-- Table des relations d'amitié
CREATE TABLE friendships (
    id INT PRIMARY KEY,
    user1_id INT REFERENCES users(id),
    user2_id INT REFERENCES users(id),
    created_date DATE
);
-- Requête : Trouver les amis d'amis (3 jointures)
SELECT DISTINCT u3.name 
FROM users u1
JOIN friendships f1 ON u1.id = f1.user1_id
JOIN friendships f2 ON f1.user2_id = f2.user1_id  
JOIN users u3 ON f2.user2_id = u3.id
WHERE u1.name = 'Alice';
```

> Graphe équivalent (Neo4j) :

```
// Deux utilisateurs et leur amitié
CREATE (alice:User {name: 'Alice',
                    email: 'alice@email.com'}),
       (bob:User {name: 'Bob', email: 'bob@email.com'}),
       (alice)-[:FRIEND {since: date('2024-01-15')}]->(bob);

// Requête : les amis d'amis d'Alice
MATCH (:User {name: 'Alice'})-[:FRIEND]->()
      -[:FRIEND]->(fof:User)
RETURN DISTINCT fof.name;
```


## 7.2 Approche de conception

> Le passage d’un schéma relationnel à un graphe suit une règle simple : chaque table d’entités devient une étiquette, chaque ligne un nœud et chaque clé étrangère une relation. Une table d’association qui relie seulement deux entités devient une relation, qui porte les colonnes de l’association comme…

```
(:Customer)-[:PLACED]->(:Order)-[:CONTAINS]->(:OrderItem)
(:OrderItem)-[:OF_PRODUCT]->(:Product)
(:Product)-[:BELONGS_TO]->(:Category)
(:Seller)-[:SOLD]->(:OrderItem)
(:Seller)-[:LOCATED_IN]->(:Geolocation)
(:Order)-[:PAID_BY]->(:Payment)
(:Customer)-[:WROTE]->(:Review)-[:ABOUT]->(:Product)
```


## 7.3.1 Installer Neo4j avec Docker

> Le fichier compose.yaml du dossier ch07-neo4j démarre le serveur, nommé neo4j, avec le mot de passe MotDePasse123 et la bibliothèque APOC. Il rend aussi le dossier import du dépôt visible par LOAD CSV :

```
% cd bd-modernes/ch07-neo4j
% docker compose up -d
```

> Sans le dépôt, la commande suivante démarre le même serveur, sans APOC :

```
% docker run -d --name neo4j \
      -p 7474:7474 -p 7687:7687 \
      -e NEO4J_AUTH=neo4j/MotDePasse123 \
      neo4j:2026-community
```


## 7.3.3 Installer Neo4j Community Server sous Linux

> Sous Ubuntu ou Debian, Neo4j s’installe à partir de son dépôt APT. Il faut d’abord ajouter la clé de signature et le dépôt, puis installer le paquet et définir le mot de passe initial avant le premier démarrage :

```
# Clé de signature et dépôt de Neo4j
K=/etc/apt/keyrings/neotechnology.gpg
D="https://debian.neo4j.com stable latest"
sudo mkdir -p /etc/apt/keyrings
wget -O - https://debian.neo4j.com/neotechnology.gpg.key \
  | sudo gpg --dearmor -o $K
sudo chmod a+r $K
echo "deb [signed-by=$K] $D" \
  | sudo tee /etc/apt/sources.list.d/neo4j.list
# Installation et mot de passe initial
sudo apt-get update
sudo apt-get install neo4j
sudo neo4j-admin dbms set-initial-password MotDePasse123
sudo systemctl enable --now neo4j
```


## 7.3.4 Utiliser Neo4j Browser

> Quelques tests :

```
// Vérifier la connexion
RETURN 'Bonjour Neo4j !' AS message;

// Créer un premier nœud de test
CREATE (test:TestNode {name: "Premier test",
                       created: datetime()});

// Vérifier qu'il a été créé
MATCH (test:TestNode) RETURN test;

// Le supprimer
MATCH (test:TestNode) DELETE test;
```


## 7.3.5 Vérifier l’installation et charger les données

> La commande suivante exécute une requête avec l’outil cypher-shell du conteneur :

```
% docker exec -it neo4j cypher-shell -u neo4j \
       -p MotDePasse123 --format plain \
       "RETURN 'Bonjour Neo4j !' AS message;"
```

> Le résultat attendu est le suivant :

```
message
"Bonjour Neo4j !"
```

> Le graphe de commerce électronique de l’étude de cas TechMarket est chargé à partir des fichiers CSV du jeu de données public Olist. Ces fichiers et le script de chargement se trouvent dans deux dépôts du cours. Copiez les fichiers CSV dans le dossier import, puis corrigez le fichier order_reviews.c…

```
% git clone https://github.com/rodrigueNTprojects/tp_levelDB_IND500.git
% git clone https://github.com/rodrigueNTprojects/Neo4j_projet.git
% cp tp_levelDB_IND500/data/*.csv import/
% (cd import && python3 ../Neo4j_projet/clean_csv.py)
% sed -f corriger_chargement.sed \
      Neo4j_projet/script_chargement.cypher \
    | docker exec -i neo4j cypher-shell -u neo4j -p MotDePasse123
```

> Vérifiez ensuite le graphe obtenu. La requête suivante compte les nœuds de chaque étiquette ; elle doit trouver notamment 112 650 articles (OrderItem), 103 886 paiements, 99 441 clients, 99 441 commandes, 98 410 avis, 32 951 produits et 3 095 vendeurs :

```
% docker exec neo4j cypher-shell -u neo4j -p MotDePasse123 \
    "MATCH (n) RETURN labels(n)[0] AS etiquette, count(*) AS nb
     ORDER BY nb DESC;"
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker compose down -v
```


## 7.4 Créer des contraintes et des index

> Contraintes :

```
// Contrainte d'unicité
CREATE CONSTRAINT customer_id_unique 
FOR (c:Customer) REQUIRE c.customer_id IS UNIQUE;
// Contrainte d'existence (édition Enterprise)
CREATE CONSTRAINT customer_email_exists 
FOR (c:Customer) REQUIRE c.email IS NOT NULL;
// Contrainte de type (édition Enterprise)
CREATE CONSTRAINT customer_email_string
FOR (c:Customer) REQUIRE c.email IS :: STRING;
```

> Index :

```
// Index simple
CREATE INDEX customer_city_index 
FOR (c:Customer) ON (c.city);
// Index composite
CREATE INDEX customer_location_index 
FOR (c:Customer) ON (c.city, c.state);
// Index de texte intégral et recherche
CREATE FULLTEXT INDEX product_text
FOR (p:Product) ON EACH [p.name, p.description];
CALL db.index.fulltext.queryNodes('product_text',
                                  'casque sans fil')
YIELD node, score
RETURN node.name, score;
// Index de points, pour les requêtes spatiales
CREATE POINT INDEX geo_location
FOR (g:Geolocation) ON (g.location);
// Lister les contraintes et les index
SHOW CONSTRAINTS;
SHOW INDEXES;
```


## Trouver tous les nœuds d’une étiquette

> MATCH est la clause fondamentale de Cypher : elle décrit un motif à rechercher dans le graphe. Voici ses principales formes.

```
// Cypher : Simple et direct
MATCH (c:Customer)
RETURN c;
```


## Filtrer sur des propriétés dans le motif

> La requête retourne tous les nœuds d’étiquette Customer : Neo4j ne lit que les nœuds de cette étiquette, et non tous les nœuds de la base.

```
// Cypher : Filtrage intégré dans le pattern
MATCH (c:Customer {state: 'SP', city: 'sao paulo'})
RETURN c.customer_id, c.customer_unique_id;
```


## Suivre des relations

> Dans le jeu de données Olist, les noms de villes sont écrits en minuscules et sans accents : « sao paulo » et non « São Paulo ». L’index composite sur (city, state) de la section 7.4 permet une recherche directe, sans parcourir tous les clients.

```
// Cypher : Pattern visuel intuitif
MATCH (c:Customer)-[:PLACED]->(o:Order)
RETURN c.customer_id, o.order_id;
```


## OPTIONAL MATCH

> Neo4j suit directement les relations PLACED enregistrées avec chaque client, sans calculer de jointure.

```
// Retourne TOUS les clients, même ceux sans commande
MATCH (c:Customer)
OPTIONAL MATCH (c)-[:PLACED]->(o:Order)
RETURN c.customer_id, COUNT(o) as order_count;
```


## Motifs de longueur variable

> OPTIONAL MATCH conserve chaque client, même s’il n’a passé aucune commande : la variable o vaut alors NULL, et COUNT(o), qui ignore les valeurs nulles, vaut 0.

```
// Produits achetés par un client : un chemin de trois
// relations, de types PLACED, CONTAINS puis OF_PRODUCT
MATCH (c:Customer {customer_id: 'CUST_001'})
      -[:PLACED|CONTAINS|OF_PRODUCT*3]->(p:Product)
RETURN DISTINCT p.product_id;
```


## Créer des nœuds

> CREATE ajoute des nœuds et des relations au graphe, sans qu’il soit nécessaire de déclarer un schéma à l’avance. Voici ses principales formes.

```
// Cypher : Création flexible, propriétés dynamiques
CREATE (c:Customer {
    customer_id: 'CUST_001',
    city: 'São Paulo',
    state: 'SP',
    signup_date: datetime(),
    preferences: ['electronics', 'books']
});
```


## Créer des relations qui portent des propriétés

> Une propriété peut contenir une liste de valeurs simples, comme preferences ; elle ne peut toutefois pas contenir de document imbriqué, qui deviendrait plutôt un nœud.

```
// Une relation peut porter ses propres propriétés
MATCH (c:Customer {customer_id: 'CUST_001'})
MATCH (p:Product {product_id: 'PROD_001'})
CREATE (c)-[:VIEWED {
    date: datetime(),
    duration_s: 45,
    channel: 'mobile_app'
}]->(p);
```


## Différence entre CREATE, MATCH et MERGE

> MERGE : trouve le motif s’il existe, sinon le crée.

```
// MATCH : trouve le client, ou ne retourne rien
MATCH (c:Customer {customer_id: 'CUST_001'}) RETURN c;
// CREATE : crée un nouveau nœud, même s'il en existe un
CREATE (c:Customer {customer_id: 'CUST_001'}) RETURN c;
// MERGE : trouve le client ou le crée
MERGE (c:Customer {customer_id: 'CUST_001'}) RETURN c;
```


## Filtrer sur des propriétés

> La clause WHERE filtre les résultats d’un MATCH. En Cypher, elle peut porter sur les propriétés des nœuds et des relations, mais aussi sur l’existence d’un motif.

```
// Commandes livrées depuis 2018 dans deux États
MATCH (c:Customer)-[:PLACED]->(o:Order)
WHERE c.state IN ['SP', 'RJ']
  AND o.purchase_timestamp >= datetime('2018-01-01')
  AND o.status = 'delivered'
RETURN c.customer_id, COUNT(o) AS delivered_orders;
```


## Filtrer sur l’existence d’un motif

> Les commandes du jeu de données Olist ont été passées de 2016 à 2018.

```
// Clients qui n'ont publié aucun avis sur un produit acheté
MATCH (c:Customer)-[:PLACED]->(:Order)
      -[:CONTAINS]->(:OrderItem)-[:OF_PRODUCT]->(p:Product)
WHERE NOT EXISTS {
  (c)-[:WROTE]->(:Review)-[:ABOUT]->(p)
}
RETURN DISTINCT c.customer_id AS customers_without_reviews;

```


## 7.5.4 Fonctions d’agrégation

> L’exemple suivant calcule, pour chaque client, le nombre de commandes et d’articles ainsi que les montants dépensés :

```
// Statistiques d'achat de chaque client
MATCH (c:Customer)-[:PLACED]->(o:Order)
      -[:CONTAINS]->(oi:OrderItem)
RETURN c.customer_id,
       c.city,
       COUNT(DISTINCT o) AS order_count,
       COUNT(oi) AS item_count,
       SUM(oi.price) AS total_spent,
       AVG(oi.price) AS avg_item_price,
       MAX(o.purchase_timestamp) AS last_order_date;
```

> Signification

```
order_count
COUNT(DISTINCT o)
```

> Nombre de commandes distinctes passées par ce client

```
item_count
COUNT(oi)
```

> Nombre total d’articles achetés (tous articles de toutes commandes)

```
total_spent
SUM(oi.price)
```

> Montant total dépensé (somme des prix de tous les articles)

```
avg_item_price
AVG(oi.price)
```

> Prix moyen par article acheté

```
last_order_date
MAX(o.purchase_timestamp)
```


## Rassembler des valeurs avec COLLECT

> Date de la dernière commande (commande la plus récente)

```
// Catégories achetées et historique de chaque client
MATCH (c:Customer)-[:PLACED]->(o:Order)
      -[:CONTAINS]->(oi:OrderItem)
      -[:OF_PRODUCT]->(p:Product)
      -[:BELONGS_TO]->(cat:Category)
RETURN c.customer_id,
       COLLECT(DISTINCT cat.name) AS purchased_categories,
       COLLECT({
           order_id: o.order_id,
           product: p.product_id,
           price: oi.price,
           date: o.purchase_timestamp
       }) AS purchase_history,
       COUNT(DISTINCT o) AS order_count;
```


## 7.5.5 Résumé des requêtes Cypher

> Comme MATCH mais retourne NULL si le motif est absent

```
OPTIONAL MATCH (p)-[:KNOWS]->(f)
```

> Filtre les résultats

```
WHERE n.age > 18
```

> Retourne les résultats

```
RETURN n.name, n.age
```

> Passe les résultats à la clause suivante

```
WITH n, count(*) as cnt
```

> Trie les résultats

```
ORDER BY n.name DESC
```

> Limite le nombre de résultats

```
LIMIT 10
```

> Saute les n premiers résultats

```
SKIP 20
```

> Élimine les doublons

```
RETURN DISTINCT n.city
```

> Combine plusieurs requêtes

```
MATCH (n) RETURN n UNION MATCH (m) RETURN m
```

> Combine avec doublons

```
... UNION ALL ...
```

> Transforme une liste en lignes

```
UNWIND [1,2,3] as x
```

> Vérifie l’existence d’un motif

```
WHERE EXISTS { (n)-[:KNOWS]->() }
```

> Condition if/then/else

```
CASE WHEN n.age > 18 THEN 'adult' END
```

> Crée des nœuds/relations (crée toujours)

```
CREATE (n:Person {name: 'Alice'})
```

> Trouve ou crée (évite les doublons)

```
MERGE (n:Person {id: '123'})
```

> Modifie ou ajoute des propriétés ou des étiquettes

```
SET n.age = 30, n:Active
```

> Supprime des propriétés ou des étiquettes

```
REMOVE n.age, n:Inactive
```

> Supprime des nœuds/relations

```
DELETE n
```

> Supprime nœud + ses relations

```
DETACH DELETE n
```

> Action si MERGE crée

```
ON CREATE SET n.created = timestamp()
```

> Action si MERGE trouve le motif

```
ON MATCH SET n.updated = timestamp()
```

> Itère et exécute des actions

```
FOREACH (x IN [1,2,3] | CREATE (:Node {val: x}))

```


## Les outils d’analyse des requêtes

> EXPLAIN : EXPLAIN montre comment Neo4j prévoit d’exécuter votre requête, sans l’exécuter réellement. C’est comme un GPS qui vous montre le trajet avant de partir.

```
EXPLAIN
MATCH (c:Customer {customer_id: 'CUST123'})
      -[:PLACED]->(o:Order)
RETURN c.customer_id, COUNT(o) AS order_count;
```

> PROFILE : PROFILE exécute la requête et fournit des statistiques détaillées sur le temps d’exécution et les ressources consommées. C’est le chronomètre de course.

```
PROFILE
MATCH (c:Customer {customer_id: 'CUST123'})
      -[:PLACED]->(o:Order)-[:CONTAINS]->(oi:OrderItem)
WHERE oi.price > 100
RETURN c.customer_id,
       SUM(oi.price) AS total_high_value_purchases;
```


## La grappe Neo4j

> Le fichier neo4j.conf de chacun des trois serveurs d’une grappe minimale contient les paramètres suivants ; seule l’adresse annoncée change d’un serveur à l’autre :

```
# Adresse d'écoute et adresse annoncée du serveur
server.default_listen_address=0.0.0.0
server.default_advertised_address=srv1
# Serveurs à contacter pour former la grappe
dbms.cluster.endpoints=srv1:6000,srv2:6000,srv3:6000
# Copies primaires et secondaires des nouvelles bases
initial.dbms.default_primaries_count=3
initial.dbms.default_secondaries_count=0
```

> Une fois la grappe formée, la topologie de chaque base se choisit en Cypher, dans la base system. La base suivante compte trois copies primaires et deux copies secondaires, ce qui demande au moins cinq serveurs :

```
CREATE DATABASE ventes
TOPOLOGY 3 PRIMARIES 2 SECONDARIES;
SHOW DATABASES;
```

> Un exemple de flow avec le consensus de Raft est le suivant :

```
1. Client A propose X=1
2. Leader distribue la proposition aux followers
3. Majorité confirme (2/3 ou 3/5)
4. Leader applique et confirme au client
5. Tous les serveurs sont synchronisés


```


## Les bases composites

> Dans l’exemple suivant, la base composite ventes regroupe les bases des Amériques et de l’Europe, puis une requête parcourt ses deux constituants :

```
CREATE COMPOSITE DATABASE ventes;
CREATE ALIAS ventes.ameriques FOR DATABASE `ventes-am`;
CREATE ALIAS ventes.europe FOR DATABASE `ventes-eu`;

UNWIND graph.names() AS g
CALL {
  USE graph.byName(g)
  MATCH (c:Customer)-[:PLACED]->(o:Order)
  RETURN c.customer_id AS client, o.total AS total
}
RETURN client, total;
```


## Service de graphe centralisé

> Écriture (Write) :

```
                                                                Client → API Gateway → Order Service
                                                                Order Service → INSERT INTO orders
                                                                Order Service → Neo4j (copie primaire cheffe)
                                                                Copie cheffe → autres copies primaires
                                                                Copies primaires → copies secondaires
```

> Lecture complexe (Read) :

```
                                                                Client → API Gateway → Neo4j Cluster
                                                                Requête: "Recommandations pour client X"
                                                                Traverse graphe directement
                                                                Copie secondaire → Client (Retourne résultats sans appels inter-services)
```


## Architecture orientée événements

> Order Service → PostgreSQL ( INSERT INTO orders VALUES (...))

```
                                                                Order Service → Kafka
                                                                Kafka → Neo4j Consumer (délivrance de l’événement au consumer Neo4j)
                                                                Neo4j Consumer → Désérialisation et transformation de l’événement
                                                                Consumer → copie primaire cheffe
                                                                Neo4j → Replication (propagation vers followers et replicas)
```


## CQRS (Command Query Responsibility Segregation) avec Neo4j

> Command (écriture):

```
                                                                Client → Command API
                                                                Command API → Command Handler (validation et routage vers handler approprié)
                                                                Command Handler → PostgreSQL (transaction ACID)
                                                                Command Handler → Event Store
                                                                PostgreSQL → Kafka (capture automatique des changements (Change Data Capture))
```

> Query (lecture):

```
                                                                Client → Query API (demande de données complexes)
                                                                Query API → Recommendation Service (routage vers service spécialisé)
                                                                Recommandation Service → copie secondaire de Neo4j (Requête Cypher optimisée sur modèle dénormalisé)
                                                                Neo4j → Client
```


## Considérations à prendre en compte pour le déploiement de Neo4j dans un contexte distribué

> Lien de documentation

```
Helm Charts Neo4j
Graphique Helm officiel qui déploie chaque serveur de la grappe et sa configuration
Un serveur par installation du graphique neo4j/neo4j : helm install server-1 neo4j/neo4j -f server-1.yaml, où le fichier de valeurs fixe neo4j.name, neo4j.minimumClusterSize: 3 et l’édition Enterprise ; répéter pour server-2 et server-3.
```

> https://neo4j.com/docs/operations-manual/current/kubernetes/helm-charts-setup/

```
Persistent Volumes (PV)
Stockage durable qui persiste même si un pod Neo4j est détruit - Les données graphe survivent aux redémarrages, migrations, ou pannes de nœuds
Sans PV : Pod Neo4j redémarre → toutes les données perdues
Avec PV : Pod redémarre → se reconnecte au volume → données intactes
```

> https://kubernetes.io/docs/concepts/storage/persistent-volumes/

```
Service Discovery
Permet aux applications de trouver automatiquement les instances Neo4j disponibles
-Votre microservice se connecte à neo4j-service.default.svc.cluster.local:7687
-Kubernetes route automatiquement vers un serveur disponible
-Un serveur tombe → Kubernetes route vers les autres sans intervention
```

> https://kubernetes.io/docs/concepts/services-networking/service/

```
Rolling Updates
Met à jour Neo4j progressivement (un pod à la fois) sans interruption - Zero downtime lors des mises à jour de version ou configuration
-Mise à jour Neo4j 2026.09 → 2026.10
Kubernetes met à jour le serveur 1, attend qu’il soit prêt, puis met à jour les serveurs 2 et 3
-Le cluster reste disponible pendant toute l’opération
```


## Considérations à prendre en compte pour le monitoring distribué de Neo4j

> Lien de documentation

```
Prometheus + Grafana : les métriques du cluster
-Prometheus : Collecte automatiquement les métriques Neo4j toutes les 15 secondes
-Grafana : Affiche ces métriques dans des tableaux de bord visuels
-Métriques Neo4j surveillées :
Performance : Temps de réponse des requêtes, débit (requêtes/s) - Ressources : CPU, mémoire, E/S disque par instance - Cluster : Statut Raft, lag de réplication, élections de leader - Métier : Nombre de nœuds/relations, taille du graphe, cache hit rate
# Exemple d'alerte ; le nom des métriques dépend
# de la version et du préfixe configuré
- alert: Neo4jTasEleve
  expr: neo4j_dbms_vm_heap_used > 3e9
  annotations:
    summary: "Tas Java élevé : {{ $labels.instance }}"
Prometheus: https://prometheus.io/download/
Grafana: https://grafana.com/grafana/download
Dashboards Neo4j: https://neo4j.com/docs/operations-manual/current/monitoring/metrics/expose/

Jaeger : traçage distribué des requêtes
Trace le parcours complet d’une requête à travers tous les services
Vous voyez que 95% du temps est dans Neo4j → vous optimisez la requête Cypher avec un index → temps passe de 3s à 200ms
Téléchargement: https://www.jaegertracing.io/download/
Intégration Neo4j: Via drivers avec OpenTelemetry
ELK Stack : Centralisation des logs
Elasticsearch: stocke et indexe tous les logs (recherche full-text rapide)
Logstash: collecte et transforme les logs de tous les services
Kibana: interface de recherche et visualisation des logs
En 30 secondes, vous identifiez qu’une contrainte d’unicité Neo4j a bloqué la création d’une commande → vous corrigez le bug dans Order Service
Elasticsearch: https://www.elastic.co/downloads/elasticsearch
Logstash: https://www.elastic.co/downloads/logstash
Kibana: https://www.elastic.co/downloads/kibana
Health Checks Kubernetes: Détection automatique des pannes
Kubernetes vérifie automatiquement l’état de santé de chaque pod Neo4j
Le serveur Neo4j 2 se fige (interblocage) → Liveness échoue → Kubernetes redémarre le pod automatiquement
Le serveur Neo4j 3 redémarre (1 minute) → Readiness échoue → trafic redirigé vers serveurs 1 et 2 → utilisateurs ne voient rien
```
