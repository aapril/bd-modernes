#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre7.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre7.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre7.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 7 : Neo4j ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch07-neo4j && docker compose down -v >/dev/null 2>&1; docker compose up -d
attendre "docker exec neo4j cypher-shell -u neo4j -p MotDePasse123 'RETURN 1'"
CS="docker exec -i neo4j cypher-shell -u neo4j -p MotDePasse123 --format plain"
bloc "Version"; echo "CALL dbms.components() YIELD name, versions, edition RETURN *;" | $CS
bloc "Chargement du jeu de données (script du cours)"
[ -d tp_levelDB_IND500 ] || git clone -q --depth 1 https://github.com/rodrigueNTprojects/tp_levelDB_IND500.git
[ -d Neo4j_projet ] || git clone -q --depth 1 https://github.com/rodrigueNTprojects/Neo4j_projet.git
cp tp_levelDB_IND500/data/*.csv import/
(cd import && python3 ../Neo4j_projet/clean_csv.py)
time (sed -f corriger_chargement.sed Neo4j_projet/script_chargement.cypher | $CS 2>&1 | tail -20)
echo "MATCH (n) RETURN labels(n)[0] AS etiquette, count(*) AS nb ORDER BY nb DESC;" | $CS
echo "MATCH ()-[r]->() RETURN type(r) AS relation, count(*) AS nb ORDER BY nb DESC;" | $CS
bloc "7-1 7.1.2 Modèle de graphes vs modèle relationnel"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
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
FIN_CY
bloc "7-2 7.1.2 Modèle de graphes vs modèle relationnel"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Deux utilisateurs et leur amitié
CREATE (alice:User {name: 'Alice',
                    email: 'alice@email.com'}),
       (bob:User {name: 'Bob', email: 'bob@email.com'}),
       (alice)-[:FRIEND {since: date('2024-01-15')}]->(bob);

// Requête : les amis d'amis d'Alice
MATCH (:User {name: 'Alice'})-[:FRIEND]->()
      -[:FRIEND]->(fof:User)
RETURN DISTINCT fof.name;
FIN_CY
bloc "7-3 7.3.4 Utiliser Neo4j Browser"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Vérifier la connexion
RETURN 'Bonjour Neo4j !' AS message;

// Créer un premier nœud de test
CREATE (test:TestNode {name: "Premier test",
                       created: datetime()});

// Vérifier qu'il a été créé
MATCH (test:TestNode) RETURN test;

// Le supprimer
MATCH (test:TestNode) DELETE test;
FIN_CY
bloc "7-4 7.4 Créer des contraintes et des index"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Contrainte d'unicité
CREATE CONSTRAINT customer_id_unique 
FOR (c:Customer) REQUIRE c.customer_id IS UNIQUE;
// Contrainte d'existence (édition Enterprise)
CREATE CONSTRAINT customer_email_exists 
FOR (c:Customer) REQUIRE c.email IS NOT NULL;
// Contrainte de type (édition Enterprise)
CREATE CONSTRAINT customer_email_string
FOR (c:Customer) REQUIRE c.email IS :: STRING;
FIN_CY
bloc "7-5 7.4 Créer des contraintes et des index"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
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
FIN_CY
bloc "7-6 Trouver tous les nœuds d’une étiquette"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Cypher : Simple et direct
MATCH (c:Customer)
RETURN c;
FIN_CY
bloc "7-7 Filtrer sur des propriétés dans le motif"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Cypher : Filtrage intégré dans le pattern
MATCH (c:Customer {state: 'SP', city: 'sao paulo'})
RETURN c.customer_id, c.customer_unique_id;
FIN_CY
bloc "7-8 Suivre des relations"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Cypher : Pattern visuel intuitif
MATCH (c:Customer)-[:PLACED]->(o:Order)
RETURN c.customer_id, o.order_id;
FIN_CY
bloc "7-9 OPTIONAL MATCH"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Retourne TOUS les clients, même ceux sans commande
MATCH (c:Customer)
OPTIONAL MATCH (c)-[:PLACED]->(o:Order)
RETURN c.customer_id, COUNT(o) as order_count;
FIN_CY
bloc "7-10 Motifs de longueur variable"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Produits achetés par un client : un chemin de trois
// relations, de types PLACED, CONTAINS puis OF_PRODUCT
MATCH (c:Customer {customer_id: 'CUST_001'})
      -[:PLACED|CONTAINS|OF_PRODUCT*3]->(p:Product)
RETURN DISTINCT p.product_id;
FIN_CY
bloc "7-11 Créer des nœuds"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Cypher : Création flexible, propriétés dynamiques
CREATE (c:Customer {
    customer_id: 'CUST_001',
    city: 'São Paulo',
    state: 'SP',
    signup_date: datetime(),
    preferences: ['electronics', 'books']
});
FIN_CY
bloc "7-12 Créer des relations qui portent des propriétés"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Une relation peut porter ses propres propriétés
MATCH (c:Customer {customer_id: 'CUST_001'})
MATCH (p:Product {product_id: 'PROD_001'})
CREATE (c)-[:VIEWED {
    date: datetime(),
    duration_s: 45,
    channel: 'mobile_app'
}]->(p);
FIN_CY
bloc "7-13 Différence entre CREATE, MATCH et MERGE"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// MATCH : trouve le client, ou ne retourne rien
MATCH (c:Customer {customer_id: 'CUST_001'}) RETURN c;
// CREATE : crée un nouveau nœud, même s'il en existe un
CREATE (c:Customer {customer_id: 'CUST_001'}) RETURN c;
// MERGE : trouve le client ou le crée
MERGE (c:Customer {customer_id: 'CUST_001'}) RETURN c;
FIN_CY
bloc "7-14 Filtrer sur des propriétés"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Commandes livrées depuis 2018 dans deux États
MATCH (c:Customer)-[:PLACED]->(o:Order)
WHERE c.state IN ['SP', 'RJ']
  AND o.purchase_timestamp >= datetime('2018-01-01')
  AND o.status = 'delivered'
RETURN c.customer_id, COUNT(o) AS delivered_orders;
FIN_CY
bloc "7-15 Filtrer sur l’existence d’un motif"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
// Clients qui n'ont publié aucun avis sur un produit acheté
MATCH (c:Customer)-[:PLACED]->(:Order)
      -[:CONTAINS]->(:OrderItem)-[:OF_PRODUCT]->(p:Product)
WHERE NOT EXISTS {
  (c)-[:WROTE]->(:Review)-[:ABOUT]->(p)
}
RETURN DISTINCT c.customer_id AS customers_without_reviews;
FIN_CY
bloc "7-16 7.5.4 Fonctions d’agrégation"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
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
FIN_CY
bloc "7-17 Rassembler des valeurs avec COLLECT"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
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
FIN_CY
bloc "7-18 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
OPTIONAL MATCH (p)-[:KNOWS]->(f);
FIN_CY
bloc "7-19 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
RETURN n.name, n.age;
FIN_CY
bloc "7-20 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
RETURN DISTINCT n.city;
FIN_CY
bloc "7-21 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
MATCH (n) RETURN n UNION MATCH (m) RETURN m;
FIN_CY
bloc "7-22 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
UNWIND [1,2,3] as x;
FIN_CY
bloc "7-23 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
CREATE (n:Person {name: 'Alice'});
FIN_CY
bloc "7-24 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
MERGE (n:Person {id: '123'});
FIN_CY
bloc "7-25 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
ON CREATE SET n.created = timestamp();
FIN_CY
bloc "7-26 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
ON MATCH SET n.updated = timestamp();
FIN_CY
bloc "7-27 7.5.5 Résumé des requêtes Cypher"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
FOREACH (x IN [1,2,3] | CREATE (:Node {val: x}));
FIN_CY
bloc "7-28 Les outils d’analyse des requêtes"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
EXPLAIN
MATCH (c:Customer {customer_id: 'CUST123'})
      -[:PLACED]->(o:Order)
RETURN c.customer_id, COUNT(o) AS order_count;
FIN_CY
bloc "7-29 Les outils d’analyse des requêtes"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
PROFILE
MATCH (c:Customer {customer_id: 'CUST123'})
      -[:PLACED]->(o:Order)-[:CONTAINS]->(oi:OrderItem)
WHERE oi.price > 100
RETURN c.customer_id,
       SUM(oi.price) AS total_high_value_purchases;
FIN_CY
bloc "7-30 La grappe Neo4j"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
CREATE DATABASE ventes
TOPOLOGY 3 PRIMARIES 2 SECONDARIES;
SHOW DATABASES;
FIN_CY
bloc "7-31 Les bases composites"
$CS <<'FIN_CY' 2>&1 | awk 'NR<=40; END {if (NR>40) print "... (" NR " lignes au total)"}'
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
FIN_CY
cd ..
