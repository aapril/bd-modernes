# Chapitre 10 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 10.5.1 Le partitionnement déclaratif de PostgreSQL

> Reprenons la table des réservations du Club Sportif (chapitre 2), en la partitionnant par mois :

```
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
```

> La clé primaire doit inclure la clé de partitionnement, parce que PostgreSQL ne vérifie l’unicité qu’à l’intérieur de chaque partition. Une requête qui filtre sur temps_de_début ne lit que les partitions concernées : c’est l’élagage des partitions (partition pruning), visible avec EXPLAIN. L’archiva…

```
ALTER TABLE réservations_p
    DETACH PARTITION réservations_2023_08;
```


## 10.5.2 Distribuer les partitions avec Citus

> L’image postgres du chapitre 2 ne contient pas Citus. Pour essayer les commandes suivantes, démarrez le serveur Citus du dossier ch10-dagster du dépôt compagnon, qui écoute sur le port 5435, puis copiez-y les trois tables du Club Sportif sans leurs contraintes. L’image citusdata/citus n’est offerte …

```
% docker compose up -d citus
% docker exec pg-club pg_dump -U postgres -d club \
    -t membres -t activités -t réservations \
    --section=pre-data --section=data \
  | docker exec -i citus psql -U postgres
% docker exec -it citus psql -U postgres
```

> L’image citusdata/citus crée déjà l’extension ; la clause IF NOT EXISTS évite alors une erreur :

```
CREATE EXTENSION IF NOT EXISTS citus;

SELECT create_distributed_table('réservations', 'numéro_membre');
SELECT create_distributed_table('membres',      'numéro_membre');
SELECT create_reference_table('activités');
```


## 10.8.1 Prérequis

> Sous macOS et Linux, uv s’installe avec la commande suivante ; sous Windows, la documentation de uv donne la commande PowerShell équivalente :

```
% curl -LsSf https://astral.sh/uv/install.sh | sh
% uv --version
```


## 10.8.2 Créer le projet

> La commande create-dagster crée un projet complet : la structure des répertoires, le fichier pyproject.toml qui déclare les dépendances, l’environnement virtuel et le fichier uv.lock qui fige les versions. Le fichier uv.lock est versionné dans Git avec le reste du projet, de sorte que tous les membr…

```
% uvx create-dagster@latest project club-sportif
% cd club-sportif
% source .venv/bin/activate         # Windows : .venv\Scripts\activate
% uv add pandas sqlalchemy "psycopg[binary]" pyarrow
% uv add --dev pytest
% dg --version
```

> Le projet créé a la structure suivante. Tout fichier Python placé dans le répertoire defs est chargé automatiquement par Dagster : il n’est plus nécessaire d’énumérer à la main chaque actif dans un objet Definitions.

```
club-sportif/
├── pyproject.toml
├── uv.lock
├── src/club_sportif/
│   ├── definitions.py      # point d’entrée, généré
│   └── defs/               # vos actifs, ressources et capteurs
└── tests/
```

> Démarrez ensuite le serveur PostgreSQL du chapitre 2 (le conteneur pg-club, s’il n’existe pas déjà), puis créez un fichier .env à la racine du projet. La commande dg lit automatiquement ce fichier, qui ne doit jamais être versionné dans Git puisqu’il contient un mot de passe :

```
% docker run -d --name pg-club -p 5432:5432 \
      -e POSTGRES_PASSWORD=MotDePasse123 postgres:18

# .env
DATABASE_URL=postgresql+psycopg://postgres:MotDePasse123@localhost:5432/postgres
```


## 10.8.3 Vérifier l’installation et charger les données

> Dans le dossier du projet, les commandes suivantes affichent la version de Dagster, puis vérifient que les définitions se chargent sans erreur :

```
% dg --version
% dg check defs
```

> Le résultat attendu est le suivant :

```
dg, version 1.13.30
All component YAML validated successfully.
All definitions loaded successfully.
```

> Les exemples utilisent le fichier vins.csv du chapitre 3 et la base club du chapitre 2. Copiez le fichier dans le dossier data du projet et démarrez le serveur PostgreSQL :

```
% mkdir -p data
% cp ../bd-modernes/ch03-acces-programme/donnees/vins.csv data/
% docker compose -f ../bd-modernes/ch02-postgresql/compose.yaml up -d
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% # Ctrl+C arrête dg dev
% rm -rf data/reservations     # résultats des partitions
```


## 10.9.1 Commandes de base

> Exécuter sans l’interface. La commande dg launch matérialise des actifs directement, ce qui est utile dans un script ou un pipeline d’intégration continue. Le signe + placé devant le nom sélectionne aussi les actifs dont il dépend directement ; l’astérisque sélectionne toute la chaîne des actifs en …

```
% dg launch --assets vins_bruts
% dg launch --assets "*prix_moyen_par_decennie"
```


## 10.9.2 Acquérir des données

> Reprenons le fichier des prix des vins présenté au chapitre 3. Nous voulons un pipeline qui lit le fichier CSV, vérifie sa qualité, puis charge les données dans PostgreSQL. Créez d’abord une ressource qui encapsule la connexion à la base de données. La chaîne de connexion est lue dans la variable DA…

```
# src/club_sportif/defs/ressources.py
import dagster as dg
from sqlalchemy import create_engine

class PostgresResource(dg.ConfigurableResource):
    url: str

    def moteur(self):
        return create_engine(self.url)

@dg.definitions
def ressources():
    return dg.Definitions(resources={
        "postgres": PostgresResource(url=dg.EnvVar("DATABASE_URL"))})
```

> Déclarez ensuite deux actifs dans un autre fichier du répertoire defs. Le premier lit le fichier brut ; le second dépend du premier et le charge dans une table. Dagster déduit cette dépendance du nom du paramètre vins_bruts. La table s’appelle vins_dagster pour ne pas remplacer la table vins créée à…

```
# src/club_sportif/defs/vins.py
import dagster as dg
import pandas as pd
from .ressources import PostgresResource

COLONNES = ["année", "prix", "pluie_hiver", "tmsc",
            "pluie_récolte", "âge", "pop_france"]

@dg.asset(group_name="vins")
def vins_bruts(context: dg.AssetExecutionContext) -> pd.DataFrame:
    df = pd.read_csv("data/vins.csv")
    df.columns = COLONNES
    context.log.info(f"{len(df)} lignes lues")
    return df

@dg.asset(group_name="vins")
def table_vins(vins_bruts: pd.DataFrame,
               postgres: PostgresResource) -> dg.MaterializeResult:
    vins_bruts.to_sql("vins_dagster", postgres.moteur(),
                      if_exists="replace", index=False)
    return dg.MaterializeResult(metadata={"lignes": len(vins_bruts)})
```

> Ajoutez une vérification de qualité. Elle s’exécute après chaque matérialisation de vins_bruts, et son résultat apparaît dans l’interface à côté de l’actif. Le paramètre blocking=True empêche les actifs suivants de s’exécuter si la vérification échoue : des données invalides ne seront jamais chargée…

```
@dg.asset_check(asset=vins_bruts, blocking=True)
def prix_positifs(vins_bruts: pd.DataFrame) -> dg.AssetCheckResult:
    invalides = int((vins_bruts["prix"] <= 0).sum())
    return dg.AssetCheckResult(passed=invalides == 0,
                               metadata={"invalides": invalides})
```


## 10.9.3 Faire des requêtes sur les données

> Un actif peut aussi être le résultat d’une requête SQL sur des données déjà chargées. L’actif suivant calcule le prix moyen des vins par décennie. Comme table_vins ne retourne pas de valeur Python (elle écrit dans PostgreSQL), la dépendance est déclarée explicitement avec le paramètre deps. La condi…

```
@dg.asset(group_name="vins", deps=[table_vins],
          automation_condition=dg.AutomationCondition.on_cron(
              "0 6 * * *"))
def prix_moyen_par_decennie(
        postgres: PostgresResource) -> pd.DataFrame:
    sql = """
        SELECT (année / 10) * 10           AS décennie,
               ROUND(AVG(prix)::numeric, 2) AS prix_moyen,
               COUNT(*)                     AS nb_millésimes
        FROM vins_dagster GROUP BY 1 ORDER BY 1;"""
    return pd.read_sql(sql, postgres.moteur())
```


## 10.9.4 Partitions et reprises

> Les données du Club Sportif arrivent jour après jour. Recharger chaque nuit toutes les réservations depuis l’ouverture du club serait inutilement coûteux. Une partition découpe un actif en tranches, ici une par jour ; Dagster sait alors quelles journées ont été traitées, lesquelles ont échoué et les…

```
# src/club_sportif/defs/reservations.py
from pathlib import Path
import dagster as dg
import pandas as pd
from .ressources import PostgresResource

jours = dg.DailyPartitionsDefinition(start_date="2023-07-01")

@dg.asset(partitions_def=jours, group_name="club",
          automation_condition=dg.AutomationCondition.eager())
def reservations_du_jour(context: dg.AssetExecutionContext,
                         postgres: PostgresResource) -> None:
    jour = context.partition_key                  # ex. 2023-09-14
    df = pd.read_sql(
        "SELECT * FROM réservations "
        "WHERE temps_de_début::date = %(jour)s",
        postgres.moteur(), params={"jour": jour})
    dossier = Path("data/reservations")
    dossier.mkdir(parents=True, exist_ok=True)
    df.to_parquet(dossier / f"date={jour}.parquet")
    context.add_output_metadata({"lignes": len(df)})
```


## 10.9.5 Réagir à l’arrivée d’un fichier avec un capteur

> Une planification n’est pas toujours appropriée. Le fournisseur du fichier des vins dépose une nouvelle version à un moment imprévisible ; il serait préférable de recharger les données dès que le fichier change. Un capteur vérifie périodiquement une condition et demande une exécution lorsqu’elle est…

```
# src/club_sportif/defs/capteurs.py
import os
import dagster as dg

@dg.sensor(target=dg.AssetSelection.groups("vins"),
           minimum_interval_seconds=60)
def nouveau_fichier_vins(context: dg.SensorEvaluationContext):
    chemin = "data/vins.csv"
    if not os.path.exists(chemin):
        return dg.SkipReason("Aucun fichier vins.csv")
    modifie = str(os.path.getmtime(chemin))
    if modifie == context.cursor:
        return dg.SkipReason("Fichier inchangé")
    context.update_cursor(modifie)
    return dg.RunRequest(run_key=modifie)
```


## 10.9.6 Stocker les résultats avec un gestionnaire d’entrées et sorties

> Lorsqu’un actif retourne une valeur, comme le DataFrame de prix_moyen_par_decennie, Dagster doit la conserver pour la transmettre aux actifs suivants. Par défaut, il la sérialise dans un fichier local. Un gestionnaire d’entrées et sorties permet de choisir un autre emplacement sans modifier le code …

```
# src/club_sportif/defs/ressources.py (suite)
import pandas as pd

class PostgresIOManager(dg.ConfigurableIOManager):
    url: str

    def handle_output(self, context: dg.OutputContext,
                      obj: pd.DataFrame) -> None:
        table = context.asset_key.path[-1]
        obj.to_sql(table, create_engine(self.url),
                   if_exists="replace", index=False)

    def load_input(self, context: dg.InputContext) -> pd.DataFrame:
        table = context.upstream_output.asset_key.path[-1]
        return pd.read_sql_table(table, create_engine(self.url))

# remplace la fonction ressources() de la section 10.9.2
@dg.definitions
def ressources():
    url = dg.EnvVar("DATABASE_URL")
    return dg.Definitions(resources={
        "postgres": PostgresResource(url=url),
        "io_manager": PostgresIOManager(url=url)})
```


## 10.9.7 Tester les actifs

> Un actif Dagster est une fonction Python : on peut donc le tester comme n’importe quelle fonction, avec pytest. Le premier test appelle directement la fonction de vérification ; le second matérialise un actif dans un environnement de test, avec ses dépendances réelles :

```
# tests/test_vins.py
import dagster as dg
import pandas as pd
from club_sportif.defs.vins import prix_positifs, vins_bruts

def test_prix_negatif_detecte():
    df = pd.DataFrame({"prix": [10.0, -2.0]})
    assert not prix_positifs(df).passed

def test_lecture_du_fichier():
    resultat = dg.materialize([vins_bruts])
    assert resultat.success
    assert len(resultat.output_for_node("vins_bruts")) > 0
```
