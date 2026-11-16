"""Chapitre 11 : écrit les réservations du Club Sportif dans le lac de données.

Pour chaque journée, le programme écrit un fichier CSV dans la zone bronze et un
fichier Parquet dans la zone argent du compartiment lac-club de MinIO, en suivant
le partitionnement de type Hive de la section 11.3.2 (date=AAAA-MM-JJ).
"""
import io
import boto3
import pandas as pd
from sqlalchemy import create_engine

PG = "postgresql+psycopg://postgres:MotDePasse123@localhost:5432/club"
S3 = dict(endpoint_url="http://localhost:9000",
          aws_access_key_id="minioadmin", aws_secret_access_key="minioadmin")
COMPARTIMENT = "lac-club"

df = pd.read_sql(
    """SELECT numéro_réservation AS numero_reservation,
              numéro_activité    AS numero_activite,
              numéro_membre      AS numero_membre,
              temps_de_début     AS temps_de_debut,
              emplacement
       FROM réservations""", create_engine(PG))
df["date"] = df["temps_de_debut"].dt.date.astype(str)

s3 = boto3.client("s3", **S3)
if COMPARTIMENT not in [b["Name"] for b in s3.list_buckets().get("Buckets", [])]:
    s3.create_bucket(Bucket=COMPARTIMENT)

for jour, groupe in df.groupby("date"):
    lignes = groupe.drop(columns="date")
    s3.put_object(Bucket=COMPARTIMENT,
                  Key=f"bronze/reservations/date={jour}/res.csv",
                  Body=lignes.to_csv(index=False).encode())
    tampon = io.BytesIO()
    lignes.to_parquet(tampon, index=False)
    s3.put_object(Bucket=COMPARTIMENT,
                  Key=f"argent/reservations/date={jour}/part-0.parquet",
                  Body=tampon.getvalue())
print(f"{len(df)} réservations écrites pour {df['date'].nunique()} journées.")
