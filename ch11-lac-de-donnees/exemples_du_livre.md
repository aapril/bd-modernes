# Chapitre 11 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 11.3.2 Le partitionnement des fichiers

> Pour éviter de lire tout le lac à chaque requête, on range les fichiers selon des préfixes qui encodent les valeurs d’une colonne, souvent la date. Cette convention, héritée de Hive, utilise la forme colonne=valeur :

```
s3://lac-club/argent/reservations/date=2023-09-13/part-0.parquet
s3://lac-club/argent/reservations/date=2023-09-14/part-0.parquet
```


## 11.4 Installer MinIO et manipuler des objets

> MinIO, présenté à la section 11.1, offre une API compatible avec S3 et s’exécute sur un poste de travail. L’image de Chainguard (cgr.dev/chainguard/minio) contient à la fois le serveur et le client mc (Chainguard s.d.). Le fichier compose.yaml du dossier ch11-lac-de-donnees démarre le serveur, nommé…

```
% cd bd-modernes/ch11-lac-de-donnees
% docker compose up -d
% python3 -m venv .venv && source .venv/bin/activate
% pip install -r requirements.txt
```

> Sans le dépôt, la commande suivante démarre le même serveur :

```
% docker run -d --name minio -p 9000:9000 -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    cgr.dev/chainguard/minio server /data --console-address ":9001"
```

> La commande suivante interroge le point de santé de MinIO ; elle doit retourner le code 200 :

```
% curl -s -o /dev/null -w "%{http_code}\n" \
       http://localhost:9000/minio/health/live
```

> Le résultat attendu est le suivant :

```
200
```

> Les fichiers vins.csv et Films.json viennent du chapitre 3. Les réservations du Club Sportif sont lues dans la base club : le programme exporter_reservations.py du dossier les écrit, une journée par fichier, dans la zone bronze (CSV) et dans la zone argent (Parquet) du compartiment lac-club, comme l…

```
% python exporter_reservations.py
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker compose down -v
```

> La console Web, accessible à l’adresse http://localhost:9001, se limite maintenant à un explorateur d’objets. En ligne de commande, le client mc, exécuté dans le conteneur avec docker exec, manipule les compartiments et les objets. Le fichier vins.csv du chapitre 3 est visible dans le conteneur sous…

```
% docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
% docker exec minio mc mb local/lac-club
% docker exec minio mc cp /donnees/vins.csv local/lac-club/bronze/vins/vins.csv
% docker exec minio mc ls --recursive local/lac-club
```

> En Python, la bibliothèque boto3, le client officiel d’AWS, fonctionne aussi avec MinIO. Le paramètre endpoint_url est la seule différence avec Amazon S3 :

```
import boto3

s3 = boto3.client("s3", endpoint_url="http://localhost:9000",
                  aws_access_key_id="minioadmin",
                  aws_secret_access_key="minioadmin")
s3.upload_file("../ch03-acces-programme/donnees/Films.json", "lac-club", "bronze/films/Films.json")
for obj in s3.list_objects_v2(Bucket="lac-club",
                              Prefix="bronze/")["Contents"]:
    print(obj["Key"], obj["Size"])
```


## 11.5.1 Amazon Athena

> Amazon Athena est un service de requêtes SQL sans serveur, basé sur le moteur libre Trino. On déclare une table externe qui décrit les fichiers d’un préfixe S3 ; la table est enregistrée dans le catalogue AWS Glue, et Athena facture selon la quantité de données lues.

```
CREATE EXTERNAL TABLE reservations (
    numero_reservation int, numero_activite int,
    numero_membre int, temps_de_debut timestamp,
    emplacement int)
PARTITIONED BY (`date` string)
STORED AS PARQUET
LOCATION 's3://lac-club/argent/reservations/';

MSCK REPAIR TABLE reservations;   -- découvre les partitions
```


## 11.5.2 DuckDB

> DuckDB est une BD analytique embarquée, souvent décrite comme le SQLite de l’analyse. Elle s’exécute dans le processus de l’application (Python, R, ligne de commande), sans serveur, et lit directement les fichiers Parquet, CSV et JSON, y compris sur S3. C’est un excellent outil pour explorer un lac …

```
INSTALL httpfs; LOAD httpfs;
CREATE SECRET minio (TYPE s3, KEY_ID 'minioadmin',
       SECRET 'minioadmin', ENDPOINT 'localhost:9000',
       URL_STYLE 'path', USE_SSL false);

SELECT date, count(*) AS reservations,
       sum(emplacement) / 2.0 AS heures
FROM   read_parquet('s3://lac-club/argent/reservations/*/*.parquet',
                    hive_partitioning = true)
WHERE  date >= '2023-09-01'
GROUP  BY date ORDER BY date;
```


## 11.6 Les formats de table ouverts et le lakehouse

> Avec Trino, une table Iceberg se crée et s’interroge en SQL standard. Athena accepte les mêmes requêtes, mais sa syntaxe de création diffère un peu : PARTITIONED BY (day(temps_de_debut)) et TBLPROPERTIES ('table_type' = 'ICEBERG').

```
CREATE TABLE lac.reservations (
    numero_reservation int, numero_membre int,
    numero_activite int, temps_de_debut timestamp(6),
    emplacement int)
WITH (format = 'PARQUET',
      partitioning = ARRAY['day(temps_de_debut)']);

DELETE FROM lac.reservations WHERE numero_membre = 58;

SELECT count(*) FROM lac.reservations
FOR TIMESTAMP AS OF TIMESTAMP '2023-09-01 00:00:00 UTC';
```


## 11.7 Étude de cas : le lac de données du Club Sportif

> Étape 2 : nettoyer vers la zone argent. Un programme Python lit le fichier brut, vérifie les types, retire les doublons et écrit un fichier Parquet partitionné par date. La bibliothèque pandas lit et écrit directement dans MinIO grâce à s3fs (pip install pandas pyarrow s3fs) :

```
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
```

> Étape 3 : agréger vers la zone or. Une requête DuckDB calcule le nombre d’heures réservées pour chaque activité, par semaine, et écrit le résultat dans la zone or, où le tableau de bord le lit :

```
COPY (
  SELECT numero_activite,
         date_trunc('week', temps_de_debut) AS semaine,
         sum(emplacement) / 2.0 AS heures_reservees
  FROM   read_parquet(
           's3://lac-club/argent/reservations/*/*.parquet',
           hive_partitioning = true)
  GROUP  BY ALL
) TO 's3://lac-club/or/occupation_hebdo.parquet' (FORMAT parquet);
```
