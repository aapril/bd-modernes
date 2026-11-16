#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre2.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre2.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre2.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 2 : PostgreSQL 18 ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch02-postgresql && docker compose down -v >/dev/null 2>&1; docker compose up -d
attendre "docker exec pg-club psql -U postgres -d club -c 'select 1 from réservations limit 1'"
bloc "Version"; docker exec pg-club psql -U postgres -c "select version();"
bloc "Vérification des 26 figures du chapitre 2"; ./verifier.sh
bloc "Blocs des sections 2.2.2 à 2.2.5, dans une base vide (essai)"
docker exec pg-club psql -U postgres -c "DROP DATABASE IF EXISTS essai" -c "CREATE DATABASE essai"
docker exec -i pg-club psql -U postgres -d essai -e <<'FIN_SQL'
\echo '=== bloc 2-1 (2.2.2 Création d’une BD en SQL (CREATE DATABASE et TABLE))'
CREATE TABLE membres
(
    numéro_membre integer NOT NULL, 
    nom_famille character varying(200) NOT NULL, 
    prénom character varying(200) NOT NULL, 
    adresse character varying(300) NOT NULL, 
    codepostal character varying(6) NOT NULL, 
    téléphone character varying(20) NOT NULL, 
    recommandé_par integer,
    ancienneté timestamp without time zone not null
);
;
\echo '=== bloc 2-2 (2.2.2 Création d’une BD en SQL (CREATE DATABASE et TABLE))'
CREATE TABLE activités
(
    numéro_activité integer NOT NULL, 
    nom character varying(100) NOT NULL, 
    coût_pour_memmbre numeric NOT NULL, 
    coût_pour_invités numeric NOT NULL, 
    mise_de_fonds_initiale numeric NOT NULL, 
    maintenance_mensuelle numeric NOT NULL 
);
;
\echo '=== bloc 2-3 (2.2.2 Création d’une BD en SQL (CREATE DATABASE et TABLE))'
CREATE TABLE réservations
(
    numéro_réservation integer NOT NULL, 
    numéro_activité integer NOT NULL, 
    numéro_membre integer NOT NULL, 
    temps_de_début timestamp without time zone NOT NULL,
    emplacement integer NOT NULL
);
;
\echo '=== bloc 2-4 (2.2.3 Contraintes d’intégrité (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK))'
ALTER TABLE membres ADD CONSTRAINT membres_pk
    PRIMARY KEY (numéro_membre);
ALTER TABLE activités ADD CONSTRAINT activités_pk
    PRIMARY KEY (numéro_activité);
ALTER TABLE réservations ADD CONSTRAINT réservations_pk
    PRIMARY KEY (numéro_réservation);
ALTER TABLE membres ADD CONSTRAINT membres_recommandé_fk
    FOREIGN KEY (recommandé_par)
    REFERENCES membres (numéro_membre)
    ON DELETE SET NULL;
ALTER TABLE réservations
    ADD CONSTRAINT réservations_membre_fk
    FOREIGN KEY (numéro_membre)
    REFERENCES membres (numéro_membre);
ALTER TABLE réservations
    ADD CONSTRAINT réservations_activité_fk
    FOREIGN KEY (numéro_activité)
    REFERENCES activités (numéro_activité);
ALTER TABLE réservations
    ADD CONSTRAINT emplacement_positif
    CHECK (emplacement > 0);
;
\echo '=== bloc 2-5 (2.2.3 Contraintes d’intégrité (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK))'
INSERT INTO réservations
    VALUES (99999, 42, 1, '2023-09-01 10:00', 2);
ERROR:  insert or update on table
        "réservations" violates foreign key
        constraint "réservations_membre_fk"
;
\echo '=== bloc 2-6 (2.2.4 Types SQL (PostgreSQL 18))'
SELECT '12.34'::float8::numeric::money ;
;
\echo '=== bloc 2-7 (2.2.4 Types SQL (PostgreSQL 18))'
SELECT '52093.89'::money::numeric::float8 ;
;
\echo '=== bloc 2-8 (2.2.5 Modification et suppression d’une table (ALTER et DROP))'
ALTER TABLE activités 
RENAME COLUMN coût_pour_memmbre TO       
              coût_pour_membre;
;
\echo '=== bloc 2-9 (2.2.6 Le dictionnaire de données SQL (INFORMATION_SCHEMA))'
SELECT table_name,table_type 
FROM information_schema.tables
WHERE table_schema = 'public' 
ORDER BY table_name ;
;
\echo '=== bloc 2-10 (2.2.7 Les fonctions d’information de session et la vue pg_stat_activity)'
SELECT * from pg_stat_activity;
;
\echo '=== bloc 2-11 (2.2.7 Les fonctions d’information de session et la vue pg_stat_activity)'
SELECT * FROM pg_stat_activity
WHERE state = 'idle';
;
\echo '=== bloc 2-12 (2.2.7 Les fonctions d’information de session et la vue pg_stat_activity)'
SELECT current_timestamp - query_start AS runtime, datname, usename FROM pg_stat_activity
WHERE state = 'active';
;
FIN_SQL
bloc "Blocs des sections 2.3 et suivantes, dans une copie de la base club (travail)"
docker exec pg-club psql -U postgres -c "DROP DATABASE IF EXISTS travail" -c "CREATE DATABASE travail TEMPLATE club"
docker exec -i pg-club psql -U postgres -d travail -e <<'FIN_SQL'
\echo '=== bloc 2-13 (2.3.1 L’instruction SELECT)'
SELECT     nom, coût_pour_membre
FROM        activités;
;
\echo '=== bloc 2-14 (2.3.2 Sélection sur une table (FROM WHERE))'
SELECT     *
FROM        activités
WHERE        coût_pour_membre > 0 AND 
coût_pour_membre < 10;
;
\echo '=== bloc 2-15 (2.3.2 Sélection sur une table (FROM WHERE))'
    SELECT     numéro_activité, nom, coût_pour_membre, 
maintenance_mensuelle     
    FROM    activités
;
\echo '=== bloc 2-16 (2.3.3 Recherche sur une chaîne de caractères (Like))'
SELECT     *
FROM        activités
WHERE        nom LIKE '%Tennis%';
;
\echo '=== bloc 2-17 (2.3.4 Concaténation de chaînes (||))'
SELECT     nom_famille || ', ' || prénom as "nom"
FROM        membres
ORDER BY     nom_famille
Limit        5 ;
;
\echo '=== bloc 2-18 (2.3.5 Opération élément de (IN))'
SELECT     *
FROM        activités
WHERE        numéro_activité IN (1,5);
;
\echo '=== bloc 2-19 (2.3.6 Expression conditionnelle (CASE))'
SELECT     nom, 
        CASE WHEN (maintenance_mensuelle > 100) THEN
        'chère'
ELSE       'économique'
END AS     coût
    FROM    activités;
;
\echo '=== bloc 2-20 (2.3.7 Les dates et les heures)'
SELECT     numéro_membre, nom_famille, prénom
FROM        membres
WHERE        ancienneté >= '2023-09-01';
;
\echo '=== bloc 2-21 (2.3.8 Éliminer les duplicatas et ordonner les résultats (DISTINCT et ORDER BY))'
SELECT ALL nom_famille 
FROM membres
ORDER BY nom_famille
LIMIT 10;
;
\echo '=== bloc 2-22 (2.3.8 Éliminer les duplicatas et ordonner les résultats (DISTINCT et ORDER BY))'
SELECT DISTINCT nom_famille 
FROM membres
ORDER BY nom_famille
LIMIT 10;
;
\echo '=== bloc 2-23 (2.3.9 Opérations ensemblistes (UNION, INTERSECT et EXCEPT))'
SELECT nom_famille 
FROM membres
UNION
SELECT nom
FROM activités
ORDER BY nom_famille
LIMIT 10;
;
\echo '=== bloc 2-24 (2.3.10 Agrégation avec MAX)'
SELECT MAX(ancienneté) AS plusrécente 
FROM membres;
;
\echo '=== bloc 2-25 (2.3.10 Agrégation avec MAX)'
SELECT prénom, nom_famille, ancienneté
FROM membres
WHERE ancienneté =
      (SELECT MAX(ancienneté) 
       FROM membres);
;
\echo '=== bloc 2-26 (2.3.11 Les jointures (INNER, LEFT, RIGHT, FULL et auto-jointure))'
SELECT temps_de_début 
FROM
    réservations res
    INNER JOIN membres mems
          ON mems.numéro_membre = res.numéro_membre
WHERE 
    mems.prénom='David'
    AND mems.nom_famille='Farrell'
ORDER BY temps_de_début
LIMIT 10 ;
;
\echo '=== bloc 2-27 (2.3.11 Les jointures (INNER, LEFT, RIGHT, FULL et auto-jointure))'
SELECT res.temps_de_début AS début,
       act.nom AS nom 
FROM
    activités act
    INNER JOIN réservations res
    ON act.numéro_activité = res.numéro_activité
WHERE 
    act.numéro_activité IN (0,1) AND
    res.temps_de_début >= '2023-09-01' AND
                res.temps_de_début < '2023-09-02'
            ORDER BY res.temps_de_début ;
;
\echo '=== bloc 2-28 (2.3.11 Les jointures (INNER, LEFT, RIGHT, FULL et auto-jointure))'
SELECT mem.prénom AS pré_mem,
       mem.nom_famille AS nom_mem,
     res.prénom AS pré_res,
     res.nom_famille AS nom_res 
FROM
    membres mem
    LEFT OUTER JOIN membres res
    ON res.numéro_membre = mem.recommandé_par
            ORDER BY nom_mem, pré_mem
            LIMIT 10 ;
;
\echo '=== bloc 2-29 (2.3.11 Les jointures (INNER, LEFT, RIGHT, FULL et auto-jointure))'
SELECT DISTINCT mem1.prénom AS prénom, mem1.nom_famille AS nom 
FROM
membres mem2
INNER JOIN membres mem1
       ON mem1.numéro_membre = mem2.recommandé_par
    ORDER BY nom, prénom
    Limit 5 ;
;
\echo '=== bloc 2-30 (2.4.1 Opérations arithmétiques et fonctions d’agrégation)'
SELECT count(*) FROM activités;
;
\echo '=== bloc 2-31 (2.4.1 Opérations arithmétiques et fonctions d’agrégation)'
SELECT 
   SUM(maintenance_mensuelle)
    FROM activités;
;
\echo '=== bloc 2-32 (2.4.2 Fonctions prédéfinies SQL)'
SELECT EXTRACT(DAY FROM TIMESTAMP '2001-02-16 20:38:40');
;
\echo '=== bloc 2-33 (2.4.2 Fonctions prédéfinies SQL)'
SELECT date_trunc('hour', INTERVAL '3 days 02:47:33');
;
\echo '=== bloc 2-34 (2.4.3 Regroupement avec GROUP BY et HAVING)'
SELECT recommandé_par, count(*)
FROM membres
WHERE recommandé_par is not null
GROUP BY recommandé_par
ORDER BY recommandé_par ;
;
\echo '=== bloc 2-35 (2.4.4 Test d’ensemble non vide (EXISTS))'
SELECT m.prénom, m.nom_famille
FROM membres m
WHERE EXISTS (SELECT *
              FROM réservations r
              WHERE r.numéro_membre = m.numéro_membre
                AND r.numéro_activité = 6)
ORDER BY m.nom_famille;
;
\echo '=== bloc 2-36 (2.4.5 Test de double (UNIQUE))'
SELECT m.numéro_membre, m.nom_famille
FROM   membres m
WHERE  UNIQUE (SELECT r.temps_de_début
               FROM   réservations r
               WHERE  r.numéro_membre = m.numéro_membre);
;
\echo '=== bloc 2-37 (2.4.5 Test de double (UNIQUE))'
SELECT   numéro_membre, temps_de_début, COUNT(*) AS nb
FROM     réservations
GROUP BY numéro_membre, temps_de_début
HAVING   COUNT(*) > 1;
;
\echo '=== bloc 2-38 (2.4.5 Test de double (UNIQUE))'
ALTER TABLE réservations
ADD CONSTRAINT réservation_unique
UNIQUE (numéro_membre, temps_de_début);
;
\echo '=== bloc 2-39 (2.4.5 Test de double (UNIQUE))'
CREATE UNIQUE INDEX réservation_unique
    ON réservations (numéro_membre, temps_de_début)
    WHERE numéro_membre <> 0;
;
\echo '=== bloc 2-40 (2.4.6 Quantificateurs (ALL, SOME/ANY))'
SELECT nom, maintenance_mensuelle
FROM   activités
WHERE  maintenance_mensuelle >= ALL (SELECT maintenance_mensuelle
                                     FROM   activités);
;
\echo '=== bloc 2-41 (2.4.6 Quantificateurs (ALL, SOME/ANY))'
SELECT nom, coût_pour_invités
FROM   activités
WHERE  coût_pour_invités > ANY (SELECT coût_pour_membre
                                FROM   activités);
;
\echo '=== bloc 2-42 (2.4.7 Test d’inclusion entre deux tables et division)'
SELECT m.numéro_membre, m.prénom, m.nom_famille
FROM   membres m
WHERE  NOT EXISTS (
         SELECT *
         FROM   activités a
         WHERE  NOT EXISTS (
                  SELECT *
                  FROM   réservations r
                  WHERE  r.numéro_membre   = m.numéro_membre
                  AND    r.numéro_activité = a.numéro_activité));
;
\echo '=== bloc 2-43 (2.4.7 Test d’inclusion entre deux tables et division)'
SELECT   r.numéro_membre
FROM     réservations r
GROUP BY r.numéro_membre
HAVING   COUNT(DISTINCT r.numéro_activité) =
         (SELECT COUNT(*) FROM activités);
;
\echo '=== bloc 2-44 (2.4.7 Test d’inclusion entre deux tables et division)'
SELECT numéro_activité FROM activités
EXCEPT
SELECT numéro_activité FROM réservations
WHERE  numéro_membre = 1;
;
\echo '=== bloc 2-45 (2.4.9 Opérations sur les chaînes de caractères)'
SELECT * 
FROM activités
WHERE nom
LIKE '___________T______2';
;
\echo '=== bloc 2-46 (2.4.9 Opérations sur les chaînes de caractères)'
SELECT RPAD(nom,10,'+') 
FROM activités
;
\echo '=== bloc 2-47 (2.4.9 Opérations sur les chaînes de caractères)'
SELECT nom_famille,
       SUBSTRING(codepostal FROM 1 FOR 3) AS région
FROM   membres;
;
\echo '=== bloc 2-48 (2.4.9 Opérations sur les chaînes de caractères)'
SELECT nom,
       SUBSTRING(nom FROM 1
                 FOR POSITION(' ' IN nom) - 1) AS premier_mot
FROM   activités
WHERE  POSITION(' ' IN nom) > 0;
;
\echo '=== bloc 2-49 (2.4.9 Opérations sur les chaînes de caractères)'
SELECT nom
FROM   activités
WHERE  nom SIMILAR TO '%(Tennis|Squash)%';
;
\echo '=== bloc 2-50 (2.4.9 Opérations sur les chaînes de caractères)'
SELECT téléphone,
       TRANSLATE(téléphone, '()- ', '') AS téléphone_normalisé
FROM   membres;
;
\echo '=== bloc 2-51 (2.4.9 Opérations sur les chaînes de caractères)'
SELECT REGEXP_REPLACE(
         REGEXP_REPLACE(téléphone, '[^0-9]', '', 'g'),
         '^([0-9]{3})([0-9]{3})([0-9]{4})$',
         '(\1) \2-\3') AS téléphone_formaté
FROM   membres;
;
\echo '=== bloc 2-52 (2.4.10 Les expressions de table communes (WITH et WITH RECURSIVE))'
WITH revenus AS (
    SELECT a.nom,
           SUM(CASE WHEN r.numéro_membre = 0
                    THEN a.coût_pour_invités
                    ELSE a.coût_pour_membre END
               * r.emplacement) AS revenu
    FROM   réservations r
    JOIN   activités a ON a.numéro_activité = r.numéro_activité
    GROUP  BY a.nom
)
SELECT nom, revenu
FROM   revenus
WHERE  revenu > (SELECT AVG(revenu) FROM revenus)
ORDER  BY revenu DESC;
;
\echo '=== bloc 2-53 (2.4.10 Les expressions de table communes (WITH et WITH RECURSIVE))'
WITH RECURSIVE chaîne(numéro_membre, recommandé_par, niveau) AS (
    SELECT numéro_membre, recommandé_par, 0
    FROM   membres
    WHERE  numéro_membre = 27
  UNION ALL
    SELECT m.numéro_membre, m.recommandé_par, c.niveau + 1
    FROM   membres m
    JOIN   chaîne  c ON m.numéro_membre = c.recommandé_par
)
SELECT c.niveau, m.prénom, m.nom_famille
FROM   chaîne c
JOIN   membres m ON m.numéro_membre = c.numéro_membre
ORDER  BY c.niveau;
;
\echo '=== bloc 2-54 (2.5.2 Modification de lignes dans une table (UPDATE))'
UPDATE activités 
SET mise_de_fonds_initiale = 10000       
WHERE numéro_activité = 1;
;
\echo '=== bloc 2-55 (2.5.2 Modification de lignes dans une table (UPDATE))'
UPDATE activités act 
SET coût_pour_membre = (SELECT coût_pour_membre * 1.1
               FROM activités 
               WHERE numéro_activité = 0),
    coût_pour_invités = (SELECT coût_pour_invités * 1.1
               FROM activités 
               WHERE numéro_activité = 0)
    
WHERE act.numéro_activité = 1;
;
\echo '=== bloc 2-56 (2.5.3 Suppression de lignes dans une table (DELETE))'
DELETE FROM membres WHERE numéro_membre = 37 ;
;
\echo '=== bloc 2-57 (2.5.3 Suppression de lignes dans une table (DELETE))'
DELETE FROM membres
WHERE numéro_membre 
NOT IN (SELECT numéro_membre FROM réservations) ;
;
FIN_SQL
cd ..
