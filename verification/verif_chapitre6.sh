#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre6.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre6.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre6.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 6 : TimescaleDB ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch06-timescaledb && docker compose down -v >/dev/null 2>&1; docker compose up -d
attendre "docker exec timescaledb psql -U postgres -d bourse -c 'select 1'"
docker exec -i timescaledb psql -U postgres -d bourse -e <<'FIN_SQL'
\echo '=== bloc 6-1 (6.3 Installer TimescaleDB)'
CREATE DATABASE bourse;
\c bourse
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
;
\echo '=== bloc 6-2 (6.4 Créer une hypertable et insérer des données)'
CREATE TABLE cours (
    moment   timestamptz   NOT NULL,
    symbole  text          NOT NULL,
    prix     numeric(10,2) NOT NULL,
    volume   integer
);

SELECT create_hypertable('cours',
       by_range('moment', INTERVAL '1 day'));

CREATE INDEX ON cours (symbole, moment DESC);
;
\echo '=== bloc 6-3 (6.4 Créer une hypertable et insérer des données)'
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
;
\echo '=== bloc 6-4 (6.4 Créer une hypertable et insérer des données)'
INSERT INTO cours (moment, symbole, prix, volume)
SELECT t, s,
       round((100 + 10 * sin(extract(epoch FROM t) / 86400)
              + random() * 2)::numeric, 2),
       (random() * 1000)::int
FROM   generate_series(now() - INTERVAL '30 days', now(),
                       INTERVAL '1 minute') AS t,
       unnest(ARRAY['ETS', 'CLUB', 'MTL']) AS s;
;
\echo '=== bloc 6-5 (6.5.1 Informations générales)'
SELECT chunk_name, range_start, range_end, is_compressed
FROM   timescaledb_information.chunks
WHERE  hypertable_name = 'cours'
ORDER  BY range_start DESC
LIMIT  5;
;
\echo '=== bloc 6-6 (6.5.1 Informations générales)'
EXPLAIN SELECT avg(prix) FROM cours
WHERE moment > now() - INTERVAL '2 days';

SELECT pg_size_pretty(hypertable_size('cours'));
;
\echo '=== bloc 6-7 (6.5.2 Requêtes par intervalles de temps (time_bucket))'
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
;
\echo '=== bloc 6-8 (6.5.2 Requêtes par intervalles de temps (time_bucket))'
SELECT symbole, last(prix, moment) AS dernier_prix,
       max(moment) AS dernier_moment
FROM   cours
WHERE  moment > now() - INTERVAL '1 hour'
GROUP  BY symbole;
;
\echo '=== bloc 6-9 (6.5.2 Requêtes par intervalles de temps (time_bucket))'
SELECT time_bucket_gapfill('5 minutes', moment) AS tranche,
       locf(last(prix, moment))        AS prix,
       interpolate(avg(prix))          AS prix_interpolé
FROM   cours
WHERE  symbole = 'CLUB'
AND    moment BETWEEN now() - INTERVAL '2 hours' AND now()
GROUP  BY tranche
ORDER  BY tranche;
;
\echo '=== bloc 6-10 (6.5.3 Agrégation continue)'
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
;
\echo '=== bloc 6-11 (6.5.3 Agrégation continue)'
ALTER MATERIALIZED VIEW cours_horaire
SET (timescaledb.materialized_only = false);

SELECT * FROM cours_horaire
WHERE  symbole = 'MTL' ORDER BY heure DESC LIMIT 24;
;
\echo '=== bloc 6-12 (6.5.4 Compression et stockage en colonnes)'
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
;
\echo '=== bloc 6-13 (6.5.5 Sous-échantillonner les données)'
SELECT time_bucket('5 minutes', moment) AS tranche,
       round(avg(prix), 2)         AS moyenne,
       round(stddev(prix), 3)      AS écart_type,
       min(prix) AS bas, max(prix) AS haut
FROM   cours
WHERE  symbole = 'ETS' AND moment > now() - INTERVAL '1 day'
GROUP  BY tranche ORDER BY tranche;
;
\echo '=== bloc 6-14 (6.5.5 Sous-échantillonner les données)'
SELECT time_bucket('30 minutes', moment) AS tranche,
       round(avg(prix), 2) AS moyenne, min(prix), max(prix)
FROM   cours
WHERE  symbole = 'ETS' AND moment > now() - INTERVAL '1 day'
GROUP  BY tranche ORDER BY tranche;
;
\echo '=== bloc 6-15 (6.5.5 Sous-échantillonner les données)'
SELECT time, value AS prix
FROM   unnest((SELECT lttb(moment, prix::float8, 500)
               FROM   cours WHERE symbole = 'ETS'));
;
\echo '=== bloc 6-16 (6.5.6 Politique de rétention)'
SELECT add_retention_policy('cours', INTERVAL '90 days');

SELECT job_id, proc_name, schedule_interval, next_start
FROM   timescaledb_information.jobs;
;
\echo '=== bloc 6-17 (6.6.1 Concevoir l’hypertable)'
CREATE TABLE mesures (
    moment      timestamptz  NOT NULL,
    salle       text         NOT NULL,
    temperature numeric(4,1),
    presences   smallint
);
SELECT create_hypertable('mesures',
       by_range('moment', INTERVAL '7 days'));
CREATE INDEX ON mesures (salle, moment DESC);
;
\echo '=== bloc 6-18 (6.6.2 Alimenter l’hypertable)'
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
;
\echo '=== bloc 6-19 (6.6.3 Interroger les données et gérer leur cycle de vie)'
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
;
\echo '=== bloc 6-20 (6.6.3 Interroger les données et gérer leur cycle de vie)'
SELECT time_bucket('15 minutes', moment) AS tranche, salle,
       min(temperature) AS minimum
FROM   mesures
WHERE  moment > now() - INTERVAL '1 day'
GROUP  BY tranche, salle
HAVING min(temperature) >= 26
ORDER  BY tranche;
;
\echo '=== bloc 6-21 (6.6.3 Interroger les données et gérer leur cycle de vie)'
ALTER TABLE mesures SET (
    timescaledb.enable_columnstore,
    timescaledb.segmentby = 'salle',
    timescaledb.orderby   = 'moment DESC');
CALL add_columnstore_policy('mesures',
                            after => INTERVAL '30 days');
SELECT add_retention_policy('mesures', INTERVAL '1 year');
SELECT add_retention_policy('occupation_horaire',
                            INTERVAL '5 years');
;
FIN_SQL
cd ..
