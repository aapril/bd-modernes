"""Chapitre 3 : vérifie la connexion à la base club du chapitre 2."""
import os
import psycopg

URL = os.environ.get("DATABASE_URL",
                     "postgresql://postgres:MotDePasse123@localhost:5432/club")
with psycopg.connect(URL) as con:
    version = con.execute("SHOW server_version").fetchone()[0]
    membres = con.execute("SELECT count(*) FROM membres").fetchone()[0]
print(f"Connexion réussie : PostgreSQL {version.split()[0]}")
print(f"Membres : {membres}")
ici = os.path.join(os.path.dirname(__file__), "..", "donnees")
attendus = ["vins.csv", "Films.json", "clients_utf8.xml", "films_utf8.xml",
            "personnes_utf8.xml", "nouveaux.csv"]
presents = [f for f in attendus if os.path.exists(os.path.join(ici, f))]
print("Fichiers de données :", ", ".join(presents))
manquants = [f for f in attendus if f not in presents]
if manquants:
    print("Fichiers manquants :", ", ".join(manquants))
