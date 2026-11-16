# Chapitre 6 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 6.3 Installer TimescaleDB

> L’extension TimescaleDB s’installe sur un serveur PostgreSQL existant, mais l’image timescaledb-ha de Tiger Data contient déjà PostgreSQL 18, l’extension et la boîte à outils TimescaleDB Toolkit, utilisée à la section 6.5.5. Le conteneur, nommé timescaledb, utilise le port 5433 pour ne pas entrer en…

```
% cd bd-modernes/ch06-timescaledb
% docker compose up -d
% docker exec -it timescaledb psql -U postgres -d bourse
```

> Sans le dépôt, démarrez le conteneur, puis créez vous-même la base et les extensions :

```
% docker run -d --name timescaledb -p 5433:5432 \
      -e POSTGRES_PASSWORD=MotDePasse123 \
      timescale/timescaledb-ha:pg18
% docker exec -it timescaledb psql -U postgres
postgres=# CREATE DATABASE bourse;
postgres=# \c bourse
bourse=# CREATE EXTENSION IF NOT EXISTS timescaledb;
bourse=# CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
```

> La requête suivante affiche la version de l’extension installée dans la base bourse :

```
% docker exec -it timescaledb psql -U postgres -d bourse \
    -c "SELECT extversion FROM pg_extension WHERE extname = 'timescaledb';"
```

> Le résultat attendu est le suivant :

```
 extversion
------------
 2.30.0
(1 row)
```

> Le chapitre génère lui-même ses cotations boursières fictives (section 6.4). Pour passer directement à la section 6.5, exécutez le script donnees/cours.sql, qui crée l’hypertable cours et y insère les 129 603 cotations :

```
% docker exec -i timescaledb psql -U postgres -d bourse \
       < donnees/cours.sql
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker compose down -v
```


## 6.4 Créer une hypertable et insérer des données

> Une hypertable se crée en deux temps : on crée d’abord une table PostgreSQL ordinaire, puis on la convertit avec la fonction create_hypertable en indiquant la colonne de temps et l’intervalle des fragments. Pour nos données boursières, chaque ligne représente une cotation : le moment, le symbole du …

```
CREATE TABLE cours (
    moment   timestamptz   NOT NULL,
    symbole  text          NOT NULL,
    prix     numeric(10,2) NOT NULL,
    volume   integer
);

SELECT create_hypertable('cours',
       by_range('moment', INTERVAL '1 day'));

CREATE INDEX ON cours (symbole, moment DESC);
```

> Depuis la version 2.20, une hypertable peut aussi se créer en une seule instruction, avec les options tsdb de CREATE TABLE. Depuis la version 2.23, cette forme active en plus le stockage en colonnes et crée une politique qui convertit chaque fragment dès que son intervalle est écoulé. Nous conservon…

```
CREATE TABLE cours (
    moment   timestamptz   NOT NULL,
    symbole  text          NOT NULL,
    prix     numeric(10,2) NOT NULL,
    volume   integer
) WITH (tsdb.hypertable,
        tsdb.partition_column = 'moment',
        tsdb.chunk_interval   = '1 day',
        tsdb.segmentby        = 'symbole',
        tsdb.orderby          = 'moment DESC');
```

> Pour que les exemples soient reproductibles sans abonnement à un fournisseur de données, nous générons 30 jours de cotations fictives, à raison d’une cotation par minute pour trois titres. La fonction generate_series produit les instants, et le prix suit une oscillation quotidienne à laquelle on ajo…

```
INSERT INTO cours (moment, symbole, prix, volume)
SELECT t, s,
       round((100 + 10 * sin(extract(epoch FROM t) / 86400)
              + random() * 2)::numeric, 2),
       (random() * 1000)::int
FROM   generate_series(now() - INTERVAL '30 days', now(),
                       INTERVAL '1 minute') AS t,
       unnest(ARRAY['ETS', 'CLUB', 'MTL']) AS s;
```


## 6.5.1 Informations générales

> TimescaleDB offre un ensemble de vues d’information dans le schéma timescaledb_information. La vue hypertables liste les hypertables et leurs dimensions ; la vue chunks donne, pour chaque fragment, l’intervalle de temps couvert et son état de compression :

```
SELECT chunk_name, range_start, range_end, is_compressed
FROM   timescaledb_information.chunks
WHERE  hypertable_name = 'cours'
ORDER  BY range_start DESC
LIMIT  5;
```

> Lorsque la dimension principale est de type temporel, les colonnes range_start et range_end contiennent les bornes du fragment ; si la dimension est un entier, ce sont les colonnes range_start_integer et range_end_integer qui sont utilisées. Pour vérifier l’exclusion de fragments, il suffit d’examin…

```
EXPLAIN SELECT avg(prix) FROM cours
WHERE moment > now() - INTERVAL '2 days';

SELECT pg_size_pretty(hypertable_size('cours'));
```


## 6.5.2 Requêtes par intervalles de temps (time_bucket)

> Les fonctions d’agrégation first et last, propres à TimescaleDB, retournent la valeur d’une colonne à l’instant le plus ancien ou le plus récent du groupe. Elles permettent de calculer en une seule requête les quatre valeurs d’un graphique en chandeliers : ouverture, haut, bas et fermeture.

```
SELECT time_bucket('15 minutes', moment) AS tranche,
       first(prix, moment) AS ouverture,
       max(prix)           AS haut,
       min(prix)           AS bas,
       last(prix, moment)  AS fermeture,
       sum(volume)         AS volume
FROM   cours
WHERE  symbole = 'ETS'
AND    moment > now() - INTERVAL '1 day'
GROUP  BY tranche
ORDER  BY tranche;
```

> La fonction last sert aussi à obtenir le dernier prix connu de chaque titre :

```
SELECT symbole, last(prix, moment) AS dernier_prix,
       max(moment) AS dernier_moment
FROM   cours
WHERE  moment > now() - INTERVAL '1 hour'
GROUP  BY symbole;
```

> Les données réelles ont souvent des trous : une bourse fermée la fin de semaine, un capteur en panne. Un GROUP BY sur time_bucket ne produit aucune ligne pour les intervalles vides, ce qui fausse les graphiques. La fonction time_bucket_gapfill produit une ligne pour chaque intervalle de la période d…

```
SELECT time_bucket_gapfill('5 minutes', moment) AS tranche,
       locf(last(prix, moment))        AS prix,
       interpolate(avg(prix))          AS prix_interpolé
FROM   cours
WHERE  symbole = 'CLUB'
AND    moment BETWEEN now() - INTERVAL '2 hours' AND now()
GROUP  BY tranche
ORDER  BY tranche;
```


## 6.5.3 Agrégation continue

> Voici comment créer une agrégation continue qui calcule les chandeliers horaires de chaque titre. La clause WITH NO DATA crée la vue sans la remplir immédiatement ; la politique de rafraîchissement s’en charge ensuite en arrière-plan :

```
CREATE MATERIALIZED VIEW cours_horaire
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', moment) AS heure, symbole,
       first(prix, moment) AS ouverture, max(prix) AS haut,
       min(prix) AS bas, last(prix, moment) AS fermeture,
       sum(volume) AS volume
FROM   cours
GROUP  BY heure, symbole
WITH NO DATA;

SELECT add_continuous_aggregate_policy('cours_horaire',
       start_offset      => INTERVAL '3 days',
       end_offset        => INTERVAL '1 hour',
       schedule_interval => INTERVAL '30 minutes');
```

> Toutes les 30 minutes, la politique recalcule les tranches comprises entre trois jours et une heure dans le passé. La dernière heure est volontairement exclue, parce qu’elle reçoit encore des insertions. Pour que les requêtes sur la vue incluent quand même ces données les plus récentes, on active l’…

```
ALTER MATERIALIZED VIEW cours_horaire
SET (timescaledb.materialized_only = false);

SELECT * FROM cours_horaire
WHERE  symbole = 'MTL' ORDER BY heure DESC LIMIT 24;
```


## 6.5.4 Compression et stockage en colonnes

> Depuis la version 2.18, cette fonction s’appelle columnstore dans TimescaleDB. Elle s’active en deux étapes : on indique d’abord comment organiser les données en colonnes, puis on crée une politique qui convertit automatiquement les fragments plus vieux qu’un certain âge. Le paramètre segmentby regr…

```
ALTER TABLE cours SET (
    timescaledb.enable_columnstore,
    timescaledb.segmentby = 'symbole',
    timescaledb.orderby   = 'moment DESC');

CALL add_columnstore_policy('cours',
                            after => INTERVAL '7 days');

SELECT pg_size_pretty(before_compression_total_bytes)
         AS avant,
       pg_size_pretty(after_compression_total_bytes)
         AS après
FROM   hypertable_columnstore_stats('cours');
```


## 6.5.5 Sous-échantillonner les données

> La façon la plus simple de sous-échantillonner consiste à agréger par intervalles plus larges avec time_bucket, en gardant des statistiques qui décrivent chaque intervalle : moyenne, écart type, minimum et maximum. On passe ainsi de 1 440 points par jour et par titre à 288 points avec un intervalle …

```
SELECT time_bucket('5 minutes', moment) AS tranche,
       round(avg(prix), 2)         AS moyenne,
       round(stddev(prix), 3)      AS écart_type,
       min(prix) AS bas, max(prix) AS haut
FROM   cours
WHERE  symbole = 'ETS' AND moment > now() - INTERVAL '1 day'
GROUP  BY tranche ORDER BY tranche;
```

> Avec un intervalle de 30 minutes, il ne reste que 48 points par jour : la courbe devient très lisible, mais les pointes de courte durée disparaissent dans la moyenne. C’est la limite de cette approche, qu’il est utile de corriger en affichant aussi le minimum et le maximum de chaque intervalle. Les …

```
SELECT time_bucket('30 minutes', moment) AS tranche,
       round(avg(prix), 2) AS moyenne, min(prix), max(prix)
FROM   cours
WHERE  symbole = 'ETS' AND moment > now() - INTERVAL '1 day'
GROUP  BY tranche ORDER BY tranche;
```

> Une autre approche d’agrégation consiste à choisir les points à conserver plutôt qu’à les moyenner. L’algorithme LTTB (Largest Triangle Three Buckets) sélectionne, dans chaque intervalle, le point qui préserve le mieux la forme visuelle de la courbe. Les pointes sont donc conservées. Il est offert p…

```
SELECT time, value AS prix
FROM   unnest((SELECT lttb(moment, prix::float8, 500)
               FROM   cours WHERE symbole = 'ETS'));
```


## 6.5.6 Politique de rétention

> Les séries temporelles grossissent sans fin. Il faut donc décider combien de temps conserver les données brutes. Une politique de rétention supprime automatiquement les fragments dont toutes les données sont plus vieilles que l’âge indiqué. Comme elle supprime des fragments entiers, l’opération est …

```
SELECT add_retention_policy('cours', INTERVAL '90 days');

SELECT job_id, proc_name, schedule_interval, next_start
FROM   timescaledb_information.jobs;
```


## 6.6.1 Concevoir l’hypertable

> Les deux mesures d’une salle arrivent ensemble, à la même minute : le modèle large convient. La colonne salle identifie la source ; elle entre dans l’index composé et, plus loin, dans le paramètre segmentby de la compression. Avec trois salles et une mesure par minute, le volume est d’environ 4 300 …

```
CREATE TABLE mesures (
    moment      timestamptz  NOT NULL,
    salle       text         NOT NULL,
    temperature numeric(4,1),
    presences   smallint
);
SELECT create_hypertable('mesures',
       by_range('moment', INTERVAL '7 days'));
CREATE INDEX ON mesures (salle, moment DESC);
```


## 6.6.2 Alimenter l’hypertable

> Comme à la section 6.4, la fonction generate_series produit une semaine de mesures fictives pour les salles A, B et C. La température oscille entre 18 °C et 25 °C ; la mise à jour qui suit simule ensuite un épisode de chaleur de 45 minutes dans la salle B :

```
INSERT INTO mesures (moment, salle, temperature, presences)
SELECT t, s,
       round((21 + 3 * sin(extract(epoch FROM t) / 43200)
              + random())::numeric, 1),
       (random() * 30)::int
FROM   generate_series(now() - INTERVAL '7 days', now(),
                       INTERVAL '1 minute') AS t,
       unnest(ARRAY['A', 'B', 'C']) AS s;

UPDATE mesures SET temperature = 27.5
WHERE  salle = 'B'
AND    moment BETWEEN now() - INTERVAL '2 hours'
                  AND now() - INTERVAL '75 minutes';
```


## 6.6.3 Interroger les données et gérer leur cycle de vie

> Le tableau de bord lit une agrégation continue plutôt que les mesures brutes. Sans la clause WITH NO DATA, la vue est remplie dès sa création ; la politique la rafraîchit ensuite toutes les heures :

```
CREATE MATERIALIZED VIEW occupation_horaire
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', moment) AS heure, salle,
       round(avg(presences), 1)   AS presences_moy,
       max(presences)             AS presences_max,
       round(avg(temperature), 1) AS temp_moy
FROM   mesures
GROUP  BY heure, salle;

SELECT add_continuous_aggregate_policy('occupation_horaire',
       start_offset      => INTERVAL '1 day',
       end_offset        => INTERVAL '1 hour',
       schedule_interval => INTERVAL '1 hour');
```

> L’alerte cherche les tranches de 15 minutes dont la température minimale atteint 26 °C : une tranche n’est retenue que si toutes ses mesures dépassent le seuil. Avec un épisode de 45 minutes, la requête retourne deux ou trois tranches de la salle B, selon la position de l’épisode par rapport au débu…

```
SELECT time_bucket('15 minutes', moment) AS tranche, salle,
       min(temperature) AS minimum
FROM   mesures
WHERE  moment > now() - INTERVAL '1 day'
GROUP  BY tranche, salle
HAVING min(temperature) >= 26
ORDER  BY tranche;
```

> Enfin, trois politiques fixent le cycle de vie des données : les mesures brutes sont converties en colonnes après 30 jours et supprimées après un an, alors que l’agrégation horaire, beaucoup plus petite, est conservée cinq ans. La direction garde ainsi l’historique de l’occupation, sans payer le sto…

```
ALTER TABLE mesures SET (
    timescaledb.enable_columnstore,
    timescaledb.segmentby = 'salle',
    timescaledb.orderby   = 'moment DESC');
CALL add_columnstore_policy('mesures',
                            after => INTERVAL '30 days');
SELECT add_retention_policy('mesures', INTERVAL '1 year');
SELECT add_retention_policy('occupation_horaire',
                            INTERVAL '5 years');
```
