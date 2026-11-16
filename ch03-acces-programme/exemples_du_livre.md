# Chapitre 3 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 3.1.1 Préparer l’environnement de travail

> Ce chapitre n’ajoute aucun serveur : il utilise le conteneur pg-club du chapitre 2. Le dossier ch03-acces-programme du dépôt contient un projet Maven (java/pom.xml), les dépendances Python (python/requirements.txt) et Node.js (node/package.json), ainsi que les fichiers de données. Installez les dépe…

```
% cd bd-modernes/ch03-acces-programme
% (cd java && mvn -q dependency:resolve)
% python3 -m venv .venv && source .venv/bin/activate
% pip install -r python/requirements.txt
% (cd node && npm install)
```

> Le programme python/verifier.py se connecte à la base club et affiche la version du serveur et le nombre de membres :

```
% python python/verifier.py
```

> Le résultat attendu est le suivant :

```
Connexion réussie : PostgreSQL 18.1
Membres : 31
Fichiers de données : vins.csv, Films.json, clients_utf8.xml, films_utf8.xml, personnes_utf8.xml, nouveaux.csv
```

> Les fichiers de la section 3.10 et de l’étude de cas sont dans le dossier donnees : vins.csv, Films.json, clients_utf8.xml, films_utf8.xml, personnes_utf8.xml et nouveaux.csv (exercice 3.6). Le fichier compose.yaml du chapitre 2 rend ce dossier visible dans le conteneur pg-club sous le chemin /donne…

```
% docker exec -it pg-club ls /donnees
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% deactivate                 # quitte l’environnement Python
% docker compose -f ../ch02-postgresql/compose.yaml stop
```


## 3.3.3 L’objet d’accès aux données (DAO) avec JDBC

> Le DAO définit une interface dans le vocabulaire de l’application, puis une classe qui la réalise avec JDBC (section 3.4). La couche de service ne connaît que l’interface ; elle ignore qu’il y a du SQL derrière. C’est la forme la plus directe du principe « coder par rapport aux interfaces » de la se…

```
public interface ReservationDao {
  void enregistrer(Reservation r);
  List<Reservation> parMembre(int membre);
}

public class JdbcReservationDao
    implements ReservationDao {
  private static final String INSERT =
      "INSERT INTO réservations (numéro_réservation, "
    + "numéro_activité, numéro_membre, temps_de_début, "
    + "emplacement) VALUES (?, ?, ?, ?, ?)";
  private final DataSource ds;
  public JdbcReservationDao(DataSource ds) { this.ds = ds; }

  @Override
  public void enregistrer(Reservation r) {
    try (Connection cn = ds.getConnection();
         PreparedStatement ps =
             cn.prepareStatement(INSERT)) {
      ps.setInt(1, r.id());
      ps.setInt(2, r.activite());
      ps.setInt(3, r.membre());
      ps.setObject(4, r.debut());     // LocalDateTime
      ps.setInt(5, r.demiHeures());
      ps.executeUpdate();
    } catch (SQLException e) {
      throw new AccesDonneesException(
          "Réservation non enregistrée", e);
    }
  }
  // parMembre(...) : SELECT ... WHERE numéro_membre = ?
}
```


## 3.3.4 L’enregistrement actif (Active Record)

> Avec le patron enregistrement actif, il n’y a pas de couche séparée : l’objet d’affaires hérite de méthodes de persistance et sait lui-même s’enregistrer. Le code est très court, ce qui explique la popularité de ce patron dans les cadriciels Web comme Ruby on Rails ou Django. Voici la même opération…

```
class Reservation(models.Model):
    activite = models.ForeignKey(Activite,
                   on_delete=models.PROTECT)
    membre = models.ForeignKey(Membre,
                   on_delete=models.CASCADE)
    debut = models.DateTimeField()
    demi_heures = models.PositiveSmallIntegerField()

r = Reservation(activite_id=3, membre_id=27,
                debut=datetime(2023, 9, 14, 18, 0),
                demi_heures=2)
r.save()                                   # INSERT
Reservation.objects.filter(membre_id=27)   # SELECT
```


## 3.3.5 Le dépôt (Repository) et le mappeur de données

> Le dépôt présente les objets d’affaires comme une collection : on y ajoute une réservation, on y cherche les réservations d’un membre, sans jamais parler de tables ni de SQL. Avec Spring Data JPA, il suffit de déclarer l’interface ; l’implémentation est générée à partir du nom des méthodes, et le ma…

```
public interface ReservationRepository
        extends JpaRepository<Reservation, Integer> {
  List<Reservation> findByMembreIdAndDebutAfter(
        int membreId, LocalDateTime debut);
}

@Service
public class ServiceReservation {
  private final ReservationRepository depot;
  public ServiceReservation(ReservationRepository depot) {
    this.depot = depot;
  }

  @Transactional                   // une unité de travail
  public Reservation reserver(Membre m, Activite a,
                 LocalDateTime debut, int demiHeures) {
    verifierLimiteQuotidienne(m, debut, demiHeures);
    return depot.save(
        new Reservation(m, a, debut, demiHeures));
  }
}
```


## 3.4 JDBC pour l’accès à une base de données

> Avec Maven, ajoutez la dépendance du pilote au fichier pom.xml. Utilisez la version 42.7.12 ou une version plus récente : elle corrige une faille qui permettait de désactiver silencieusement la liaison de canal (channel binding) de l’authentification SCRAM (CVE-2026-54291) :

```
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <version>42.7.12</version>
</dependency>
```

> lire le mot de passe dans une variable d’environnement plutôt que de l’écrire dans le code.

```
import java.math.BigDecimal;
import java.sql.*;

public class Activites {
  public static void main(String[] args)
      throws SQLException {
    String url = "jdbc:postgresql://localhost:5432/club";
    String sql = "SELECT nom, coût_pour_membre "
        + "FROM activités "
        + "WHERE coût_pour_membre < ? ORDER BY nom";
    try (Connection cn = DriverManager.getConnection(
             url, "club_app", System.getenv("PGPASSWORD"));
         PreparedStatement ps = cn.prepareStatement(sql)) {
      ps.setBigDecimal(1, new BigDecimal("10"));
      try (ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
          System.out.printf("%-28s %8.2f%n",
              rs.getString("nom"),
              rs.getBigDecimal("coût_pour_membre"));
        }
      }
    }
  }
}
```

> Par défaut, chaque énoncé JDBC est validé immédiatement (mode autocommit). Lorsque plusieurs modifications doivent réussir ou échouer ensemble, il faut gérer la transaction explicitement, conformément aux propriétés ACID vues au chapitre 2. L’exemple suivant, tiré de la classe JdbcReservationDao, en…

```
cn.setAutoCommit(false);
try (PreparedStatement ps = cn.prepareStatement(INSERT)) {
  for (Reservation r : nouvelles) {
    ps.setInt(1, r.id());
    ps.setInt(2, r.activite());
    ps.setInt(3, r.membre());
    ps.setObject(4, r.debut());
    ps.setInt(5, r.demiHeures());
    ps.addBatch();
  }
  ps.executeBatch();
  cn.commit();
} catch (SQLException e) {
  cn.rollback();
  throw e;
} finally {
  cn.setAutoCommit(true);
}
```


## 3.5 ODBC pour l’accès à une base de données

> La connexion est décrite par un nom de source de données (Data Source Name, DSN), enregistré une fois pour toutes dans la configuration du poste. Sous Linux, avec unixODBC, on ajoute une section au fichier odbc.ini :

```
[club]
Driver     = PostgreSQL Unicode
Servername = localhost
Port       = 5432
Database   = club
```

> Le programme Python suivant utilise la bibliothèque pyodbc pour interroger la base au moyen de ce DSN. Comme avec JDBC, les valeurs sont passées en paramètres « ? » et jamais concaténées au texte SQL. Notez que le bloc with de pyodbc valide la transaction sans fermer la connexion ; on la ferme donc …

```
import os, pyodbc

mdp = os.environ["PGPASSWORD"]
cn = pyodbc.connect(f"DSN=club;UID=club_app;PWD={mdp}")
try:
    cur = cn.cursor()
    cur.execute("""SELECT nom, coût_pour_membre
                   FROM activités
                   WHERE coût_pour_membre < ?""", 10)
    for nom, coût in cur.fetchall():
        print(f"{nom:28} {coût:8.2f}")
finally:
    cn.close()
```


## 3.6 La DB-API de Python et psycopg

> En Python, l’accès aux BD relationnelles est normalisé par la DB-API 2.0 (PEP 249). Comme JDBC en Java, elle définit des interfaces communes (connexion, curseur, execute, fetchall, commit) que chaque pilote réalise. Pour PostgreSQL, le pilote de référence est psycopg 3. C’est l’accès le plus utilisé…

```
% pip install "psycopg[binary,pool]"
```

> Le programme suivant reprend l’exemple JDBC de la section 3.4. Les blocs with ferment automatiquement la connexion et le curseur ; à la sortie du bloc de connexion, la transaction est validée, ou annulée si une exception a été levée. Les paramètres s’écrivent %s et sont toujours transmis séparément …

```
import os
from datetime import datetime
import psycopg
from psycopg.rows import dict_row

nouvelles_reservations = [
    (7001, 2, 27, datetime(2023, 9, 20, 18, 0), 2),
    (7002, 2, 28, datetime(2023, 9, 20, 19, 0), 2),
]
with psycopg.connect(os.environ["DATABASE_URL"],
                     row_factory=dict_row) as cn:
    lignes = cn.execute(
        "SELECT nom, coût_pour_membre FROM activités "
        "WHERE coût_pour_membre < %s ORDER BY nom", (10,)
    ).fetchall()
    for a in lignes:
        print(f"{a['nom']:28} {a['coût_pour_membre']:8.2f}")

    with cn.cursor() as cur:           # insertion par lots
        cur.executemany(
            "INSERT INTO réservations (numéro_réservation, "
            "numéro_activité, numéro_membre, "
            "temps_de_début, emplacement) "
            "VALUES (%s, %s, %s, %s, %s)",
            nouvelles_reservations)
```

> Pour une application serveur, le module psycopg_pool fournit un bassin de connexions, l’équivalent de HikariCP en Java. Le bloc with ouvre le bassin et le ferme proprement à la fin du programme :

```
from psycopg_pool import ConnectionPool

with ConnectionPool(os.environ["DATABASE_URL"],
                    min_size=2, max_size=10) as bassin:
    with bassin.connection() as cn:
        n = cn.execute(
            "SELECT count(*) FROM réservations "
            "WHERE numéro_membre = %s", (27,)).fetchone()[0]
        print("réservations du membre 27 :", n)
```


## 3.7.2 Exemple avec Prisma

> Avec Prisma, le schéma est décrit dans un fichier schema.prisma. Depuis Prisma 7, le bloc generator doit indiquer le dossier de sortie (output) du client généré, et l’URL de connexion se déclare dans le fichier prisma.config.ts plutôt que dans le schéma. Voici la description des tables membres et ré…

```
generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
}

model Membre {
  numero       Int           @id @map("numéro_membre")
  nomFamille   String        @map("nom_famille")
  prenom       String        @map("prénom")
  reservations Reservation[]

  @@map("membres")
}

model Reservation {
  numero     Int      @id @map("numéro_réservation")
  membreId   Int      @map("numéro_membre")
  debut      DateTime @map("temps_de_début")
                      @db.Timestamp(6)
  demiHeures Int      @map("emplacement")
  membre     Membre   @relation(fields: [membreId],
                                references: [numero])

  @@map("réservations")
}
```

> La commande npx prisma generate produit un client TypeScript typé à partir de ce schéma. Depuis Prisma 7, ce client exige un adaptateur de pilote ; pour PostgreSQL, il s’agit du paquet @prisma/adapter-pg. Le code d’application, écrit en module ECMAScript, peut alors lire les membres et leurs réserva…

```
import { PrismaClient } from "./generated/prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter });

const membres = await prisma.membre.findMany({
  where: { nomFamille: { startsWith: "T" } },
  include: { reservations: {
    where: { debut: {
      gte: new Date("2023-01-01") } } } },
  orderBy: { nomFamille: "asc" },
});
```


## 3.8.2 Exemple : un serveur qui unifie PostgreSQL, MongoDB et Redis

> Le Club Sportif a maintenant ses données dans trois SGBD : les membres et les réservations dans PostgreSQL (chapitre 2), les commentaires des membres sur les activités dans MongoDB (chapitre 5) et le classement des membres les plus actifs dans Redis (chapitre 4). Redis et MongoDB sont présentés en d…

```
type Membre {
  id: Int!
  prenom: String!
  nom: String!
  rang: Int
  reservations(limite: Int = 5): [Reservation!]!
}
type Reservation {
  debut: String!
  demiHeures: Int!
  activite: Activite!
}
type Activite {
  id: Int!
  nom: String!
  commentaires(limite: Int = 3): [Commentaire!]!
}
type Commentaire { auteur: String!, texte: String!, note: Int }
type Query { membre(id: Int!): Membre }
type Mutation {
  reserver(membre: Int!, activite: Int!, debut: String!,
           demiHeures: Int!): Reservation!
}
```

> Le serveur, écrit en Node.js avec Apollo Server, associe à chaque champ un résolveur qui interroge la bonne source. Les connexions (pg, mongodb et redis) sont créées une seule fois au démarrage :

```
import { ApolloServer } from "@apollo/server";
import { startStandaloneServer } from "@apollo/server/standalone";

const resolvers = {
  Query: {
    membre: async (_, { id }) => (await pg.query(
      "SELECT numéro_membre AS id, prénom AS prenom, " +
      "nom_famille AS nom FROM membres WHERE numéro_membre = $1",
      [id])).rows[0],
  },
  Membre: {
    rang: async (m) => {
      const r = await redis.zRevRank("classement:2023-09",
                                     `membre:${m.id}`);
      return r === null ? null : r + 1;
    },
    reservations: async (m, { limite }) => (await pg.query(
      "SELECT temps_de_début AS debut, emplacement AS " +
      "\"demiHeures\", numéro_activité AS id_activite " +
      "FROM réservations WHERE numéro_membre = $1 " +
      "ORDER BY temps_de_début DESC LIMIT $2",
      [m.id, limite])).rows,
  },
  Reservation: {
    activite: (r, _, ctx) => ctx.activites.load(r.id_activite),
  },
  Activite: {
    commentaires: (a, { limite }) =>
      mongo.collection("commentaires")
      .find({ activite: a.id }).sort({ date: -1 })
      .limit(limite).toArray(),
  },
};

const serveur = new ApolloServer({ typeDefs, resolvers });
await startStandaloneServer(serveur, {
  listen: { port: 4000 },
  context: async () => ({ activites: chargeurActivites() }),
});
```

> L’application mobile envoie alors une seule requête, qui décrit exactement les champs dont l’écran a besoin :

```
query {
  membre(id: 27) {
    prenom
    rang
    reservations(limite: 3) {
      debut
      activite { nom  commentaires(limite: 2) { auteur texte } }
    }
  }
}
```


## 3.8.3 Le problème des N+1 requêtes et DataLoader

> L’exemple précédent cache un piège déjà rencontré avec les ORM (section 3.7.3). Pour trois réservations, le résolveur activite serait appelé trois fois, et ferait trois requêtes PostgreSQL identiques à l’identifiant près. La bibliothèque DataLoader règle ce problème : elle accumule tous les identifi…

```
import DataLoader from "dataloader";

const chargeurActivites = () => new DataLoader(async (ids) => {
  const { rows } = await pg.query(
    "SELECT numéro_activité AS id, nom FROM activités " +
    "WHERE numéro_activité = ANY($1)", [ids]);
  const parId = new Map(rows.map((a) => [a.id, a]));
  return ids.map((id) => parId.get(id));   // même ordre que ids
});
```


## 3.9.1 Sécurité

> Chiffrement en transit : la connexion au SGBD utilise TLS, surtout lorsqu’il est dans le nuage.

```
-- psql -v mdp='...' -d club -f roles.sql
REVOKE CONNECT ON DATABASE club FROM PUBLIC;
CREATE ROLE club_app LOGIN PASSWORD :'mdp';
GRANT CONNECT ON DATABASE club TO club_app;
GRANT SELECT ON activités, membres TO club_app;
GRANT SELECT, INSERT, UPDATE ON réservations
      TO club_app;
```


## 3.9.3 Transactions et niveaux d’isolation

> Pour illustrer la première solution, ajoutons d’abord à la table activités du chapitre 2 une colonne places_libres, qui contient le nombre de places encore disponibles pour chaque activité. La contrainte CHECK sert de filet de sécurité : le SGBD refusera toute mise à jour qui rendrait ce nombre néga…

```
ALTER TABLE activités
ADD COLUMN places_libres integer NOT NULL DEFAULT 20
CHECK (places_libres >= 0);
UPDATE activités SET places_libres = 1
WHERE  numéro_activité = 3;    -- il ne reste qu’une place
```

> La transaction suivante réserve cette dernière place. La clause FOR UPDATE verrouille la ligne de l’activité : si un deuxième membre tente de réserver en même temps, sa transaction attend que la première soit terminée, puis lit la valeur à jour (0) ; l’application refuse alors la réservation et term…

```
BEGIN;
SELECT places_libres FROM activités
WHERE  numéro_activité = 3 FOR UPDATE; -- verrou de ligne
-- si places_libres = 0 : ROLLBACK et refus
UPDATE activités SET places_libres = places_libres - 1
WHERE  numéro_activité = 3;
INSERT INTO réservations (numéro_réservation,
       numéro_activité, numéro_membre,
       temps_de_début, emplacement)
VALUES (5001, 3, 27, '2023-09-15 18:00', 2);
COMMIT;
```


## 3.9.4 Performance

> la pagination avec OFFSET : pour afficher la 500e page de 20 lignes, le SGBD doit lire puis jeter les 9 980 lignes précédentes. La pagination par clé (keyset) reprend plutôt après la dernière ligne affichée et s’appuie sur un index composé. Les valeurs :dernier_debut et :dernier_no sont des paramètr…

```
CREATE INDEX réservations_membre_début
    ON réservations (numéro_membre,
        temps_de_début DESC, numéro_réservation DESC);

SELECT numéro_réservation, temps_de_début
FROM   réservations
WHERE  numéro_membre = 27
  AND  (temps_de_début, numéro_réservation)
       < (:dernier_debut, :dernier_no)
ORDER  BY temps_de_début DESC, numéro_réservation DESC
LIMIT  20;
```


## 3.9.5 Migrations de schéma versionnées

> Le schéma d’une BD évolue avec l’application : nouvelles tables, nouvelles colonnes, nouveaux index. Modifier la base à la main, avec un outil graphique, mène rapidement à des environnements (développement, test, production) qui ne sont plus identiques. La solution est de traiter le schéma comme du …

```
db/migration/
  V1__creer_tables.sql
  V2__ajouter_places_libres.sql
  V3__index_reservations_membre.sql

% flyway -url=jdbc:postgresql://localhost:5432/club migrate
```


## 3.9.6 Tester la couche d’accès aux données

> Les tests de la couche d’accès aux données sont des tests d’intégration : ils doivent s’exécuter contre le même SGBD qu’en production. Une base en mémoire différente (H2, SQLite) ne reproduit ni les types, ni les fonctions, ni le comportement des transactions de PostgreSQL. La bibliothèque Testconta…

```
import org.testcontainers.postgresql.PostgreSQLContainer;

@Testcontainers
class JdbcReservationDaoTest {

  @Container
  static PostgreSQLContainer pg =
      new PostgreSQLContainer("postgres:18");

  @Test
  void enregistreEtRelit() {
    PGSimpleDataSource ds = new PGSimpleDataSource();
    ds.setUrl(pg.getJdbcUrl());
    ds.setUser(pg.getUsername());
    ds.setPassword(pg.getPassword());
    Flyway.configure().dataSource(ds).load().migrate();

    ReservationDao dao = new JdbcReservationDao(ds);
    dao.enregistrer(new Reservation(1, 3, 27,
        LocalDateTime.parse("2023-09-14T18:00"), 2));
    assertEquals(1, dao.parMembre(27).size());
  }
}
```


## 3.10.2 Importer des données CSV

> Le fichier vins.csv se trouve dans ce répertoire. Créez la table suivante. Les noms de colonnes sont écrits en minuscules avec des traits de soulignement : PostgreSQL convertit en minuscules les identificateurs non délimités, et un nom comme pluieHiver deviendrait pluiehiver.

```
CREATE TABLE vins (
    année         integer PRIMARY KEY,
    prix          numeric,
    pluie_hiver   numeric,
    tmsc          numeric,
    pluie_récolte numeric,
    âge           integer,
    pop_france    numeric
);
```

> Cette petite BD, tirée de l’étude d’Ashenfelter, Ashmore et Lalonde (1995), décrit 25 millésimes de vins rouges de Bordeaux : l’année, le logarithme du prix moyen relatif au millésime 1961, les pluies d’hiver, la température moyenne de la saison de croissance (tmsc), les pluies pendant la récolte, l…

```
COPY vins (année, prix, pluie_hiver, tmsc,
           pluie_récolte, âge, pop_france)
FROM '/donnees/vins.csv'
WITH (FORMAT csv, HEADER true);
```

> La commande COPY est exécutée par le serveur PostgreSQL : le chemin du fichier est donc celui du serveur, et l’utilisateur doit être superutilisateur ou membre du rôle pg_read_server_files. Si le fichier se trouve sur votre poste et que la base est sur un autre serveur (par exemple dans le nuage), u…

```
\copy vins FROM 'vins.csv' CSV HEADER
```

> Vérifiez ensuite le résultat de l’importation avant d’utiliser les données :

```
SELECT count(*), min(année), max(année),
       round(avg(prix), 3)
FROM   vins;
```


## 3.10.3 Importer des données JSON

> Commencez par charger le fichier complet dans une table de transit qui contient une seule colonne. La fonction pg_read_file lit un fichier situé sur le serveur ; elle est réservée par défaut aux superutilisateurs. Pour un autre rôle, il faut lui accorder le droit EXECUTE sur la fonction et, pour lir…

```
CREATE TABLE films_transit (doc jsonb);
INSERT INTO films_transit
SELECT pg_read_file(
         '/donnees/Films.json')::jsonb;
```

> La fonction jsonb_array_elements transforme ensuite le tableau, atteint par le chemin doc -> 'films' -> 'film', en une ligne par film. Les opérateurs -> (qui retourne du JSON) et ->> (qui retourne du texte) permettent d’extraire les attributs. L’insertion doit indiquer INSERT 0 631 :

```
CREATE TABLE films (
    id_film  integer GENERATED ALWAYS AS IDENTITY
             PRIMARY KEY,
    titre    text NOT NULL,
    année    integer,
    détails  jsonb
);

INSERT INTO films (titre, année, détails)
SELECT f ->> 'titre',
       (f ->> 'annee')::integer,
       f
FROM   films_transit,
       jsonb_array_elements(doc -> 'films' -> 'film') AS f;
```

> Le choix de conserver le document complet dans la colonne détails illustre une approche hybride : les attributs les plus utilisés deviennent des colonnes typées, alors que le reste demeure en JSON. On peut toujours l’interroger, par exemple pour trouver les films du genre Drama à l’aide de l’opérate…

```
CREATE INDEX films_détails_gin ON films USING GIN (détails);

SELECT titre, année
FROM   films
WHERE  détails @> '{"genre": ["Drama"]}';
```


## 3.10.4 Importer des données XML

> Il est aussi possible d’importer des données en format XML. PostgreSQL offre le type xml et la fonction XMLTABLE, qui transforme un document XML en table à l’aide d’expressions XPath. Prenons le fichier clients_utf8.xml de l’étude de cas de la section 3.11. Il décrit 21 550 clients ; chacun contient…

```
<clients>
  <client id="101">
    <nom-famille>Tremblay</nom-famille>
    <prenom>Julie</prenom>
    <courriel>julie.tremblay@exemple.ca</courriel>
    <anniversaire>1984-03-12</anniversaire>
    ...
  </client>
  ...
</clients>
```

> Le document est d’abord chargé dans une table de transit, puis découpé en lignes avec XMLTABLE. La clause PATH donne, pour chaque colonne, le chemin XPath relatif à l’élément client ; remarquez que le nom de famille se trouve dans l’élément nom-famille. La table client est celle de l’étude de cas (s…

```
CREATE TABLE clients_transit (doc xml);
INSERT INTO clients_transit
SELECT XMLPARSE(DOCUMENT
       pg_read_file(
         '/donnees/clients_utf8.xml'));

INSERT INTO client (id_client, nom, prénom, courriel,
                    date_naissance)
SELECT x.*
FROM   clients_transit,
       XMLTABLE('/clients/client' PASSING doc
         COLUMNS id_client      integer PATH '@id',
                 nom            text    PATH 'nom-famille',
                 prénom         text    PATH 'prenom',
                 courriel       text    PATH 'courriel',
                 date_naissance date    PATH 'anniversaire') AS x;
```


## 3.11.2 Conception de la base de données

> La clé primaire composite (id_film, id_personne, personnage) permet qu’un même personnage soit joué par plusieurs personnes dans un film.

```
CREATE TABLE personne (
    id_personne    integer PRIMARY KEY,
    nom            varchar(100) NOT NULL,
    date_naissance date,
    lieu_naissance varchar(150),
    biographie     text
);
CREATE TABLE film (
    id_film        integer PRIMARY KEY,
    titre          varchar(200) NOT NULL,
    année          smallint
                   CHECK (année BETWEEN 1888 AND 2100),
    langue         varchar(50),
    durée_minutes  smallint CHECK (durée_minutes > 0),
    résumé         text,
    id_réalisateur integer REFERENCES personne (id_personne)
);
CREATE TABLE genre (
    id_genre integer GENERATED ALWAYS AS IDENTITY
             PRIMARY KEY,
    nom      varchar(50) NOT NULL UNIQUE
);
CREATE TABLE film_genre (
    id_film  integer REFERENCES film (id_film),
    id_genre integer REFERENCES genre (id_genre),
    PRIMARY KEY (id_film, id_genre)
);
CREATE TABLE pays (
    code char(2) PRIMARY KEY,
    nom  varchar(100) NOT NULL
);
CREATE TABLE film_pays (
    id_film   integer REFERENCES film (id_film),
    code_pays char(2) REFERENCES pays (code),
    PRIMARY KEY (id_film, code_pays)
);
CREATE TABLE scénariste (
    id_scénariste integer GENERATED ALWAYS AS IDENTITY
                  PRIMARY KEY,
    nom           varchar(100) NOT NULL UNIQUE
);
CREATE TABLE film_scénariste (
    id_film       integer REFERENCES film (id_film),
    id_scénariste integer
                  REFERENCES scénariste (id_scénariste),
    PRIMARY KEY (id_film, id_scénariste)
);
CREATE TABLE rôle (
    id_film     integer REFERENCES film (id_film),
    id_personne integer REFERENCES personne (id_personne),
    personnage  varchar(150) NOT NULL,
    PRIMARY KEY (id_film, id_personne, personnage)
);
CREATE TABLE annonce (
    id_annonce integer GENERATED ALWAYS AS IDENTITY
               PRIMARY KEY,
    id_film    integer NOT NULL REFERENCES film (id_film),
    url        varchar(300) NOT NULL
);
CREATE TABLE client (
    id_client      integer PRIMARY KEY,
    nom            varchar(100) NOT NULL,
    prénom         varchar(100) NOT NULL,
    courriel       varchar(200) NOT NULL UNIQUE,
    date_naissance date
);
CREATE TABLE carte_crédit (
    id_carte        integer GENERATED ALWAYS AS IDENTITY
                    PRIMARY KEY,
    id_client       integer NOT NULL
                    REFERENCES client (id_client),
    type_carte      varchar(20)
                    CHECK (type_carte IN
                      ('Visa', 'MasterCard',
                       'Amex')),
    quatre_derniers char(4) NOT NULL
                    CHECK (quatre_derniers ~ '^[0-9]{4}$'),
    expiration      date NOT NULL
);
```

> Le dépôt compagnon fournit, dans le dossier ch03-acces-programme/etude_de_cas, le script schema.sql (les tables ci-dessus), le script declencheur.sql (section 3.12) et le script charger.sql, qui effectue le même chargement en SQL avec XMLTABLE (section 3.10.4), dans le même ordre. Ils permettent de …

```
% docker exec pg-club createdb -U postgres location
% cat schema.sql declencheur.sql charger.sql \
    | docker exec -i pg-club psql -U postgres -d location \
        -v ON_ERROR_STOP=1
```


## 3.12 Valider les données à l’aide de contraintes et de déclencheurs

> Par exemple, la règle « un client doit avoir au moins 18 ans pour enregistrer une carte de crédit » porte sur deux tables. Elle s’écrit en PL/pgSQL de la façon suivante ; un client dont la date de naissance est inconnue est refusé, car la comparaison avec NULL ne serait jamais vraie :

```
CREATE FUNCTION vérifier_âge_client() RETURNS trigger AS $$
BEGIN
  IF (SELECT date_naissance IS NULL
             OR age(date_naissance) < interval '18 years'
      FROM client WHERE id_client = NEW.id_client) THEN
    RAISE EXCEPTION
      'Le client % doit avoir au moins 18 ans',
      NEW.id_client;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_âge_client
BEFORE INSERT OR UPDATE ON carte_crédit
FOR EACH ROW EXECUTE FUNCTION vérifier_âge_client();
```
