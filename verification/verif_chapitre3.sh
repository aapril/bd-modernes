#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre3.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre3.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre3.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 3 : importation et étude de cas ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch02-postgresql && docker compose up -d --force-recreate postgres
attendre "docker exec pg-club psql -U postgres -d club -c 'select 1'"
cd ..
bloc "Fichiers vus par le serveur"; docker exec pg-club ls -l /donnees
docker exec pg-club psql -U postgres -c "DROP DATABASE IF EXISTS essai3" -c "CREATE DATABASE essai3"
bloc "Sections 3.10.2 à 3.10.4, dans la base essai3"
docker exec -i pg-club psql -U postgres -d essai3 -e <<'FIN_SQL'
-- tables de l'étude de cas, nécessaires à la section 3.10.4
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

\echo '=== bloc 3-1 (3.10.2 Importer des données CSV)'
CREATE TABLE vins (
    année         integer PRIMARY KEY,
    prix          numeric,
    pluie_hiver   numeric,
    tmsc          numeric,
    pluie_récolte numeric,
    âge           integer,
    pop_france    numeric
);
;
\echo '=== bloc 3-2 (3.10.2 Importer des données CSV)'
COPY vins (année, prix, pluie_hiver, tmsc,
           pluie_récolte, âge, pop_france)
FROM '/donnees/vins.csv'
WITH (FORMAT csv, HEADER true);
;
\echo '=== bloc 3-3 (3.10.2 Importer des données CSV)'
SELECT count(*), min(année), max(année),
       round(avg(prix), 3)
FROM   vins;
;
\echo '=== bloc 3-4 (3.10.3 Importer des données JSON)'
CREATE TABLE films_transit (doc jsonb);
INSERT INTO films_transit
SELECT pg_read_file(
         '/donnees/Films.json')::jsonb;
;
\echo '=== bloc 3-5 (3.10.3 Importer des données JSON)'
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
;
\echo '=== bloc 3-6 (3.10.3 Importer des données JSON)'
CREATE INDEX films_détails_gin ON films USING GIN (détails);

SELECT titre, année
FROM   films
WHERE  détails @> '{"genre": ["Drama"]}';
;
\echo '=== bloc 3-7 (3.10.4 Importer des données XML)'
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
;
SELECT count(*) FROM films WHERE détails @> '{"genre": ["Drama"]}' OR détails @> '{"genre": "Drama"}';
FIN_SQL
bloc "Étude de cas 3.11 : base location"
cd ch03-acces-programme/etude_de_cas
docker exec pg-club psql -U postgres -c "DROP DATABASE IF EXISTS location"
docker exec pg-club createdb -U postgres location
cat schema.sql declencheur.sql charger.sql | docker exec -i pg-club psql -U postgres -d location -v ON_ERROR_STOP=1
bloc "Déclencheur : client de moins de 18 ans"
docker exec -i pg-club psql -U postgres -d location <<'FIN_SQL'
INSERT INTO client VALUES (1, 'Jeune', 'Léa', 'lea@exemple.ca', current_date - interval '10 years');
INSERT INTO carte_crédit (id_client, type_carte, quatre_derniers, expiration) VALUES (1, 'Visa', '1234', '2030-01-01');
SELECT f.titre, string_agg(p.nom, ', ') FROM rôle r JOIN film f USING (id_film) JOIN personne p USING (id_personne) WHERE personnage = 'Darth Vader' GROUP BY 1;
FIN_SQL
cd ../..
