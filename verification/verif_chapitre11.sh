#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre11.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre11.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre11.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 11 : MinIO et DuckDB ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch02-postgresql && docker compose up -d && cd ../ch11-lac-de-donnees && docker compose down -v >/dev/null 2>&1; docker compose up -d
attendre "curl -sf http://localhost:9000/minio/health/live"
python3 -m venv .venv >/dev/null && source .venv/bin/activate && python -m pip install -q --upgrade pip && pip install -q -r requirements.txt
for f in vins.csv Films.json; do [ -f ../ch03-acces-programme/donnees/$f ] || echo "!! fichier manquant : ch03-acces-programme/donnees/$f (à déposer par l’auteur)"; done
bloc "Santé"; curl -s -o /dev/null -w "%{http_code}\n" http://localhost:9000/minio/health/live
bloc "Commandes mc de la section 11.4"
echo '$ docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin'; docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
echo '$ docker exec minio mc mb local/lac-club'; docker exec minio mc mb local/lac-club
echo '$ docker exec minio mc cp /donnees/vins.csv local/lac-club/bronze/vins/vins.csv'; docker exec minio mc cp /donnees/vins.csv local/lac-club/bronze/vins/vins.csv
echo '$ docker exec minio mc ls --recursive local/lac-club'; docker exec minio mc ls --recursive local/lac-club
bloc "Export des réservations (exporter_reservations.py)"; python exporter_reservations.py
bloc "11-py1 11.4 Installer MinIO et manipuler des objets"
python - <<'FIN_PY'
import boto3

s3 = boto3.client("s3", endpoint_url="http://localhost:9000",
                  aws_access_key_id="minioadmin",
                  aws_secret_access_key="minioadmin")
s3.upload_file("../ch03-acces-programme/donnees/Films.json", "lac-club", "bronze/films/Films.json")
for obj in s3.list_objects_v2(Bucket="lac-club",
                              Prefix="bronze/")["Contents"]:
    print(obj["Key"], obj["Size"])
FIN_PY
bloc "11-py2 11.7 Étude de cas : le lac de données du Club Sportif"
python - <<'FIN_PY'
import pandas as pd

opts = {"key": "minioadmin", "secret": "minioadmin",
        "client_kwargs": {"endpoint_url": "http://localhost:9000"}}

brut = pd.read_csv(
    "s3://lac-club/bronze/reservations/date=2023-09-14/res.csv",
    storage_options=opts, parse_dates=["temps_de_debut"])
propre = (brut.drop_duplicates("numero_reservation")
              .query("emplacement > 0")
              .assign(date=lambda d: d.temps_de_debut.dt.date
                                      .astype(str)))
propre.to_parquet("s3://lac-club/argent/reservations/",
                  partition_cols=["date"], index=False,
                  storage_options=opts)
FIN_PY
bloc "Requêtes DuckDB (sections 11.5.2 et 11.7)"
python - <<'FIN_PY'
import duckdb
con = duckdb.connect()
sql = """INSTALL httpfs; LOAD httpfs;
CREATE SECRET minio (TYPE s3, KEY_ID 'minioadmin',
       SECRET 'minioadmin', ENDPOINT 'localhost:9000',
       URL_STYLE 'path', USE_SSL false);

SELECT date, count(*) AS reservations,
       sum(emplacement) / 2.0 AS heures
FROM   read_parquet('s3://lac-club/argent/reservations/*/*.parquet',
                    hive_partitioning = true)
WHERE  date >= '2023-09-01'
GROUP  BY date ORDER BY date;
COPY (
  SELECT numero_activite,
         date_trunc('week', temps_de_debut) AS semaine,
         sum(emplacement) / 2.0 AS heures_reservees
  FROM   read_parquet(
           's3://lac-club/argent/reservations/*/*.parquet',
           hive_partitioning = true)
  GROUP  BY ALL
) TO 's3://lac-club/or/occupation_hebdo.parquet' (FORMAT parquet);"""
for q in [x for x in sql.split(";") if x.strip()]:
    print("SQL>", q.strip()[:80])
    try:
        r = con.sql(q)
        if r is not None: print(r)
    except Exception as e: print("ERREUR :", e)
FIN_PY
deactivate; cd ..
