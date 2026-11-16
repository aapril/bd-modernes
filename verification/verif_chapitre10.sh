#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre10.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre10.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre10.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 10 : Citus et partitionnement ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch02-postgresql && docker compose up -d && cd ../ch10-dagster && docker compose down -v >/dev/null 2>&1; docker compose up -d citus
attendre "docker exec pg-club psql -U postgres -d club -c 'select 1'"
attendre "docker exec citus psql -U postgres -c 'select 1'"
bloc "Version de Citus"; docker exec citus psql -U postgres -c "select citus_version();"
bloc "Copie des tables (commande de la section 10.5.2)"
docker exec pg-club pg_dump -U postgres -d club -t membres -t activités -t réservations --section=pre-data --section=data | docker exec -i citus psql -U postgres -q
bloc "Commandes de la section 10.5.2"
docker exec -i citus psql -U postgres -e <<'FIN_SQL'
CREATE EXTENSION IF NOT EXISTS citus;
SELECT create_distributed_table('réservations', 'numéro_membre');
SELECT create_distributed_table('membres',      'numéro_membre');
SELECT create_reference_table('activités');
SELECT count(*) FROM réservations;
EXPLAIN SELECT m.nom_famille, count(*) FROM réservations r JOIN membres m USING (numéro_membre) GROUP BY 1;
FIN_SQL
bloc "Partitionnement déclaratif (section 10.5.1) sur PostgreSQL 18"
docker exec -i pg-club psql -U postgres -d club -e <<'FIN_SQL'
DROP TABLE IF EXISTS réservations_p, réservations_2023_08 CASCADE;
CREATE TABLE réservations_p (
    numéro_réservation integer   NOT NULL,
    numéro_activité    integer   NOT NULL,
    numéro_membre      integer   NOT NULL,
    temps_de_début     timestamp NOT NULL,
    emplacement        integer   NOT NULL,
    PRIMARY KEY (numéro_réservation, temps_de_début)
) PARTITION BY RANGE (temps_de_début);

CREATE TABLE réservations_2023_08 PARTITION OF réservations_p
    FOR VALUES FROM ('2023-08-01') TO ('2023-09-01');
CREATE TABLE réservations_2023_09 PARTITION OF réservations_p
    FOR VALUES FROM ('2023-09-01') TO ('2023-10-01');
CREATE TABLE réservations_défaut PARTITION OF réservations_p
    DEFAULT;
;
ALTER TABLE réservations_p
    DETACH PARTITION réservations_2023_08;
;
SELECT inhrelid::regclass AS partition FROM pg_inherits WHERE inhparent = 'réservations_p'::regclass;
FIN_SQL
cd ..
