-- Étude de cas du chapitre 3 : chargement des trois fichiers XML avec XMLTABLE.
-- Prérequis : les tables de la section 3.11.2 (et, si désiré, le déclencheur
-- de la section 3.12) existent dans la base courante ; les fichiers sont
-- visibles par le serveur sous /donnees.
-- Exécution : psql -v ON_ERROR_STOP=1 -f charger.sql
BEGIN;

CREATE TEMP TABLE transit (nom text PRIMARY KEY, doc xml);
INSERT INTO transit VALUES
  ('personnes', XMLPARSE(DOCUMENT pg_read_file('/donnees/personnes_utf8.xml'))),
  ('films',     XMLPARSE(DOCUMENT pg_read_file('/donnees/films_utf8.xml'))),
  ('clients',   XMLPARSE(DOCUMENT pg_read_file('/donnees/clients_utf8.xml')));

-- 1. Personnes
INSERT INTO personne (id_personne, nom, date_naissance, lieu_naissance, biographie)
SELECT x.id, x.nom, NULLIF(x.naissance, '')::date, x.lieu, x.bio
FROM   transit t,
       XMLTABLE('/personnes/personne' PASSING t.doc
         COLUMNS id        integer PATH '@id',
                 nom       text    PATH 'nom',
                 naissance text    PATH 'naissance/anniversaire',
                 lieu      text    PATH 'naissance/lieu',
                 bio       text    PATH 'bio') AS x
WHERE  t.nom = 'personnes';

-- 2. Films (un film par élément film)
INSERT INTO film (id_film, titre, année, langue, durée_minutes, résumé, id_réalisateur)
SELECT x.*
FROM   transit t,
       XMLTABLE('/films/film' PASSING t.doc
         COLUMNS id_film        integer  PATH '@id',
                 titre          text     PATH 'titre',
                 année          smallint PATH 'annee',
                 langue         text     PATH 'langue',
                 durée_minutes  smallint PATH 'duree',
                 résumé         text     PATH 'resume',
                 id_réalisateur integer  PATH 'realisateur/@id') AS x
WHERE  t.nom = 'films';

-- Vue intermédiaire : une ligne par élément répété d'un film.
-- Le chemin '../@id' remonte à l'élément film parent.
CREATE TEMP VIEW élément_film AS
SELECT x.id_film, x.balise, x.valeur, x.id_attr
FROM   transit t,
       XMLTABLE('/films/film/*[self::genre or self::pays or self::scenariste or self::annonce]'
         PASSING t.doc
         COLUMNS id_film integer PATH '../@id',
                 balise  text    PATH 'local-name()',
                 valeur  text    PATH '.',
                 id_attr integer PATH '@id') AS x
WHERE  t.nom = 'films';

-- 3. Genres
INSERT INTO genre (nom)
SELECT DISTINCT valeur FROM élément_film WHERE balise = 'genre' ORDER BY 1;
INSERT INTO film_genre
SELECT e.id_film, g.id_genre
FROM   élément_film e JOIN genre g ON g.nom = e.valeur
WHERE  e.balise = 'genre';

-- 4. Pays : le fichier donne le nom en anglais ; la table de correspondance
-- le traduit en code ISO 3166-1 alpha-2. L'Allemagne de l'Ouest (West Germany)
-- est rattachée au code DE de l'Allemagne.
CREATE TEMP TABLE correspondance_pays (nom_fichier text PRIMARY KEY, code char(2), nom text);
INSERT INTO correspondance_pays VALUES
  ('USA','US','États-Unis'), ('UK','GB','Royaume-Uni'), ('Germany','DE','Allemagne'),
  ('West Germany','DE','Allemagne'), ('France','FR','France'), ('Italy','IT','Italie'),
  ('Canada','CA','Canada'), ('Japan','JP','Japon'), ('Australia','AU','Australie'),
  ('Hong Kong','HK','Hong Kong'), ('New Zealand','NZ','Nouvelle-Zélande'),
  ('Czech Republic','CZ','Tchéquie'), ('Spain','ES','Espagne'), ('Sweden','SE','Suède'),
  ('Mexico','MX','Mexique'), ('Brazil','BR','Brésil'), ('India','IN','Inde'),
  ('Austria','AT','Autriche'), ('South Africa','ZA','Afrique du Sud'), ('Malta','MT','Malte'),
  ('Algeria','DZ','Algérie'), ('Taiwan','TW','Taïwan'), ('China','CN','Chine'),
  ('South Korea','KR','Corée du Sud'), ('Poland','PL','Pologne');
INSERT INTO pays (code, nom)
SELECT DISTINCT code, nom FROM correspondance_pays;
INSERT INTO film_pays
SELECT DISTINCT e.id_film, c.code
FROM   élément_film e JOIN correspondance_pays c ON c.nom_fichier = e.valeur
WHERE  e.balise = 'pays';
-- Un pays absent de la correspondance ferait échouer la vérification finale.

-- 5. Scénaristes : le fichier ne donne que le nom, sans identifiant.
INSERT INTO scénariste (nom)
SELECT DISTINCT valeur FROM élément_film WHERE balise = 'scenariste' ORDER BY 1;
INSERT INTO film_scénariste
SELECT e.id_film, s.id_scénariste
FROM   élément_film e JOIN scénariste s ON s.nom = e.valeur
WHERE  e.balise = 'scenariste';

-- 6. Annonces (adresses des bandes-annonces)
INSERT INTO annonce (id_film, url)
SELECT id_film, valeur FROM élément_film WHERE balise = 'annonce';

-- 7. Rôles
INSERT INTO rôle (id_film, id_personne, personnage)
SELECT x.*
FROM   transit t,
       XMLTABLE('/films/film/role' PASSING t.doc
         COLUMNS id_film     integer PATH '../@id',
                 id_personne integer PATH 'acteur/@id',
                 personnage  text    PATH 'personnage') AS x
WHERE  t.nom = 'films';

-- 8. Clients et cartes : seuls les quatre derniers chiffres sont conservés,
-- et le mot de passe du fichier n'est pas chargé.
INSERT INTO client (id_client, nom, prénom, courriel, date_naissance)
SELECT x.*
FROM   transit t,
       XMLTABLE('/clients/client' PASSING t.doc
         COLUMNS id_client      integer PATH '@id',
                 nom            text    PATH 'nom-famille',
                 prénom         text    PATH 'prenom',
                 courriel       text    PATH 'courriel',
                 date_naissance date    PATH 'anniversaire') AS x
WHERE  t.nom = 'clients';

INSERT INTO carte_crédit (id_client, type_carte, quatre_derniers, expiration)
SELECT x.id_client, x.carte, right(x.numéro, 4), make_date(x.année, x.mois, 1)
FROM   transit t,
       XMLTABLE('/clients/client/info-credit' PASSING t.doc
         COLUMNS id_client integer PATH '../@id',
                 carte     text    PATH 'carte',
                 numéro    text    PATH 'no',
                 mois      integer PATH 'exp-mois',
                 année     integer PATH 'exp-annee') AS x
WHERE  t.nom = 'clients';

-- Vérification : chaque pays du fichier doit avoir trouvé son code.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM élément_film e
             WHERE e.balise = 'pays'
               AND NOT EXISTS (SELECT 1 FROM correspondance_pays c
                               WHERE c.nom_fichier = e.valeur)) THEN
    RAISE EXCEPTION 'Pays sans code ISO : ajoutez-le à correspondance_pays';
  END IF;
END $$;

COMMIT;

SELECT 'personne' AS table_, count(*) FROM personne
UNION ALL SELECT 'film', count(*) FROM film
UNION ALL SELECT 'genre', count(*) FROM genre
UNION ALL SELECT 'film_genre', count(*) FROM film_genre
UNION ALL SELECT 'pays', count(*) FROM pays
UNION ALL SELECT 'film_pays', count(*) FROM film_pays
UNION ALL SELECT 'scénariste', count(*) FROM scénariste
UNION ALL SELECT 'film_scénariste', count(*) FROM film_scénariste
UNION ALL SELECT 'rôle', count(*) FROM rôle
UNION ALL SELECT 'annonce', count(*) FROM annonce
UNION ALL SELECT 'client', count(*) FROM client
UNION ALL SELECT 'carte_crédit', count(*) FROM carte_crédit;
