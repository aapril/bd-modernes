# Chapitre 2 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 2.1.5 Préparer l’environnement de travail

> Le dossier ch02-postgresql du dépôt contient un fichier compose.yaml qui démarre deux conteneurs : le serveur PostgreSQL, nommé pg-club, sur le port 5432, et pgAdmin 4, sur le port 5050. Placez-vous dans ce dossier, puis démarrez-les :

```
% cd bd-modernes/ch02-postgresql
% docker compose up -d
```

> Sans le dépôt, la commande suivante démarre le même serveur, mais sans les données :

```
% docker run -d --name pg-club -p 5432:5432 \
       -e POSTGRES_PASSWORD=MotDePasse123 postgres:18
```

> La commande suivante interroge la base club dans le conteneur ; elle doit compter 4 044 réservations :

```
% docker exec -it pg-club psql -U postgres -d club \
       -c "SELECT count(*) FROM réservations;"
```

> Le résultat attendu est le suivant :

```
 count
-------
  4044
(1 row)
```

> Au premier démarrage, le conteneur exécute le script donnees/01_club_sportif.sql, qui crée la base club et y charge les 31 membres, les 9 activités et les 4 044 réservations du Club Sportif, de juillet à septembre 2023. Pour remettre la base dans son état initial, par exemple après les mises à jour …

```
% docker exec -i pg-club psql -U postgres \
       < donnees/01_club_sportif.sql
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker compose stop      # arrête, sans rien perdre
% docker compose down -v   # supprime aussi les données
```


## 2.2.2 Création d’une BD en SQL (CREATE DATABASE et TABLE)

> Le serveur démarré à la section 2.1.5 contient déjà la base club, chargée par le script du dépôt compagnon. Pour essayer vous-même les commandes de création de cette section sans modifier cette base, créez d’abord une base d’essai :

```
CREATE DATABASE essai;
```

> La première action est de créer des tables à l’aide d’une commande CREATE TABLE selon le format suivant :

```
CREATE TABLE nomDeLaTable 
( nomColonne type
 [,nomColonne type]...
);
```

> Exemple Création du schéma de la table membres

```
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
```

> Exemple Création du schéma de la table activités

```
CREATE TABLE activités
(
    numéro_activité integer NOT NULL, 
    nom character varying(100) NOT NULL, 
    coût_pour_memmbre numeric NOT NULL, 
    coût_pour_invités numeric NOT NULL, 
    mise_de_fonds_initiale numeric NOT NULL, 
    maintenance_mensuelle numeric NOT NULL 
);
```

> Exemple Création du schéma de la table réservations

```
CREATE TABLE réservations
(
    numéro_réservation integer NOT NULL, 
    numéro_activité integer NOT NULL, 
    numéro_membre integer NOT NULL, 
    temps_de_début timestamp without time zone NOT NULL,
    emplacement integer NOT NULL
);
```


## 2.2.3 Contraintes d’intégrité (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK)

> Les principales contraintes sont la clé primaire (PRIMARY KEY), qui identifie chaque ligne de façon unique et interdit les valeurs nulles ; la clé étrangère (FOREIGN KEY … REFERENCES), qui oblige une valeur à exister dans une autre table ; l’unicité (UNIQUE) ; et la vérification (CHECK), qui impose …

```
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
```

> Le SGBD vérifie désormais chaque modification. Par exemple, l’insertion d’une réservation pour un membre et une activité qui n’existent pas est refusée. Dans la base essai, encore vide, PostgreSQL signale la première contrainte qu’il vérifie, celle du membre :

```
INSERT INTO réservations
    VALUES (99999, 42, 1, '2023-09-01 10:00', 2);
ERROR:  insert or update on table
        "réservations" violates foreign key
        constraint "réservations_membre_fk"
```


## 2.2.4 Types SQL (PostgreSQL 18)

> Les valeurs des types de données numeric, int et bigint peuvent être converties en money. La conversion à partir des types de données real et double precision peut se faire en passant d’abord par le type numeric, par exemple :

```
SELECT '12.34'::float8::numeric::money ;
```

> Cette méthode n’est toutefois pas recommandée. Les nombres à virgule flottante ne doivent pas être utilisés pour manipuler de l’argent en raison du risque d’erreurs d’arrondi. Une valeur monétaire peut être convertie en numérique sans perte de précision. La conversion vers d’autres types peut potent…

```
SELECT '52093.89'::money::numeric::float8 ;
```


## 2.2.5 Modification et suppression d’une table (ALTER et DROP)

> La commande ALTER TABLE modifie la structure d’une table existante : elle permet d’ajouter, de renommer ou de supprimer des colonnes et des contraintes. Si vous avez remarqué, nous avons fait une erreur lors de la création de la table activités avec le champ coût_pour_memmbre. Ce champ devrait être …

```
ALTER TABLE activités 
RENAME COLUMN coût_pour_memmbre TO       
              coût_pour_membre;
```


## 2.2.6 Le dictionnaire de données SQL (INFORMATION_SCHEMA)

> Lorsqu’un objet, par exemple une table, est créé à l’aide d’une commande de définition des données, le SGBD enregistre sa description dans son catalogue système. La norme SQL donne accès à ce catalogue par le schéma information_schema, un ensemble de vues en lecture seule. La requête suivante interr…

```
SELECT table_name,table_type 
FROM information_schema.tables
WHERE table_schema = 'public' 
ORDER BY table_name ;
```


## 2.2.7 Les fonctions d’information de session et la vue pg_stat_activity

> Si un utilisateur se connecte à une base de données sur un serveur, cette connexion établit une session. Dans PostgreSQL, chaque connexion ouvre sa propre session. La norme SQL définit plusieurs valeurs spéciales, que PostgreSQL offre sous forme de fonctions d’information de session ; elles indiquen…

```
SESSION_USER : cette fonction retourne le nom de l’utilisateur qui a ouvert la session en cours. Un programme de surveillance peut l’interroger pour savoir qui exécute les instructions SQL,
CURRENT_USER : cette fonction retourne le rôle dont les privilèges s’appliquent en ce moment. Il diffère de SESSION_USER après une commande SET ROLE ou dans une fonction déclarée SECURITY DEFINER ; sinon, les deux valeurs sont identiques,
SYSTEM_USER : depuis PostgreSQL 16, cette fonction retourne la méthode d’authentification et l’identité utilisées à la connexion, sous la forme méthode:identité (par exemple scram-sha-256:alice) ; elle retourne NULL lorsque la connexion n’exige aucune authentification (méthode trust). Notez que, depuis PostgreSQL 14, les mots de passe sont chiffrés par défaut avec SCRAM-SHA-256 (paramètre password_encryption), plus sûr que l’ancienne méthode md5,
```

> pg_stat_activity : cette vue système vous permet d’identifier les requêtes SQL actives pour les instances PostgreSQL. La vue pg_stat_activity affiche un processus serveur ainsi que sa session et sa requête associées dans chaque ligne. Vous pouvez utiliser pg_stat_activity pour analyser et effectuer …

```
SELECT * from pg_stat_activity;
```

> Ou, pour identifier les sessions inactives :

```
SELECT * FROM pg_stat_activity
WHERE state = 'idle';
```

>      Ou, pour identifier les sessions actives

```
SELECT current_timestamp - query_start AS runtime, datname, usename FROM pg_stat_activity
WHERE state = 'active';
```


## 2.3.1 L’instruction SELECT

> Pour obtenir la liste des activités avec leur coût pour les membres :

```
SELECT     nom, coût_pour_membre
FROM        activités;
```


## 2.3.2 Sélection sur une table (FROM WHERE)

> La clause WHERE filtre ensuite ces lignes candidates : elle contient une expression booléenne construite à partir des colonnes, et seules les lignes pour lesquelles l’expression est vraie sont conservées. Plusieurs conditions peuvent être combinées. La requête suivante retient les activités dont le …

```
SELECT     *
FROM        activités
WHERE        coût_pour_membre > 0 AND 
coût_pour_membre < 10;
```

> Prenons un autre exemple. Comment produire une liste des activités qui facturent, aux membres, moins du 1/50e de leur coût d’entretien mensuel ? Cette liste doit retourner le numéro de l’activité, son nom, et son coût pour les membres et l’entretien mensuel des activités en question.

```
    SELECT     numéro_activité, nom, coût_pour_membre, 
maintenance_mensuelle     
    FROM    activités
```


## 2.3.3 Recherche sur une chaîne de caractères (Like)

> L’opérateur LIKE compare une chaîne à un motif simple. Dans ce motif, le caractère % remplace une suite quelconque de caractères, même vide, et le caractère _ remplace exactement un caractère. LIKE fait partie de la norme SQL et est offert par tous les SGBD relationnels. La requête suivante recherch…

```
SELECT     *
FROM        activités
WHERE        nom LIKE '%Tennis%';
```


## 2.3.4 Concaténation de chaînes (||)

> L’opérateur || de SQL permet d’effectuer une opération de concaténation de chaînes de caractères. Essayons d’afficher les noms des 5 premiers membres, au format « Nom, Prénom ».

```
SELECT     nom_famille || ', ' || prénom as "nom"
FROM        membres
ORDER BY     nom_famille
Limit        5 ;
```


## 2.3.5 Opération élément de (IN)

> Pour retrouver plusieurs activités précises, par exemple les activités 1 et 5, on pourrait écrire WHERE numéro_activité = 1 OR numéro_activité = 5. L’opérateur IN est plus concis, surtout lorsque la liste de valeurs est longue : la condition est vraie si la valeur de la colonne figure dans la liste.

```
SELECT     *
FROM        activités
WHERE        numéro_activité IN (1,5);
```


## 2.3.6 Expression conditionnelle (CASE)

> Par exemple, pour étiqueter chaque activité comme « chère » si son entretien mensuel dépasse 100 $, et comme « économique » sinon, en affichant le nom de l’activité et son étiquette :

```
SELECT     nom, 
        CASE WHEN (maintenance_mensuelle > 100) THEN
        'chère'
ELSE       'économique'
END AS     coût
    FROM    activités;
```


## 2.3.7 Les dates et les heures

> Il y a beaucoup d’opérations possibles sur les dates/heures offertes par le langage SQL. Elles sont généralement écrites par ordre décroissant de grandeur : AAAA-MM-JJ HH:MM:SS.nnnnnn. Ce format ISO 8601 permet de comparer directement des horodatages (« timestamps »). Lorsqu’on ne précise que la dat…

```
CURRENT_DATE : date du jour,
CURRENT_TIME(p) : temps actuel,
CURRENT_TIMESTAMP.
```

> Faisons un exercice. Comment produire une liste des membres qui ont adhéré depuis le 1er septembre 2023 ? Retournez le numéro du membre, son nom et son prénom.

```
SELECT     numéro_membre, nom_famille, prénom
FROM        membres
WHERE        ancienneté >= '2023-09-01';
```


## 2.3.8 Éliminer les duplicatas et ordonner les résultats (DISTINCT et ORDER BY)

> Une même valeur se répète souvent d’une ligne à l’autre. Par défaut (mot-clé ALL, qui peut être omis), SELECT retourne toutes les lignes, doublons compris. La requête suivante extrait les dix premiers noms de famille par ordre alphabétique :

```
SELECT ALL nom_famille 
FROM membres
ORDER BY nom_famille
LIMIT 10;
```

> Pour qu’il n’y ait pas de duplicatas, l’énoncé DISTINCT est utilisé :

```
SELECT DISTINCT nom_famille 
FROM membres
ORDER BY nom_famille
LIMIT 10;
```


## 2.3.9 Opérations ensemblistes (UNION, INTERSECT et EXCEPT)

> Les opérations ensemblistes combinent les résultats de deux requêtes qui retournent le même nombre de colonnes, de types compatibles. UNION retourne les lignes produites par l’une ou l’autre requête, INTERSECT celles produites par les deux, et EXCEPT celles de la première qui ne figurent pas dans la…

```
SELECT nom_famille 
FROM membres
UNION
SELECT nom
FROM activités
ORDER BY nom_famille
LIMIT 10;
```


## 2.3.10 Agrégation avec MAX

> L’exemple qui suit identifie notre plus récent membre :

```
SELECT MAX(ancienneté) AS plusrécente 
FROM membres;
```

> MAX parcourt toutes les valeurs de la colonne ancienneté et retourne la plus grande, c’est-à-dire la plus récente. Pour connaître le nom de ce membre, il faut une sous-requête :

```
SELECT prénom, nom_famille, ancienneté
FROM membres
WHERE ancienneté =
      (SELECT MAX(ancienneté) 
       FROM membres);
```


## 2.3.11 Les jointures (INNER, LEFT, RIGHT, FULL et auto-jointure)

> Chaque paire retenue produit une ligne qui combine les colonnes des deux tables. Par exemple, voici les heures de début des dix premières réservations du membre David Farrell :

```
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
```

> Voyons maintenant comment obtenir les heures de début des réservations des terrains de tennis pour le 1er septembre 2023, avec le nom du terrain, en ordre chronologique :

```
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
```

> Une jointure interne ne produit une ligne que lorsque la condition de jointure est satisfaite. Une jointure externe gauche produit en plus une ligne pour chaque ligne de gauche sans correspondance, en complétant les colonnes de droite par des NULL. Elle convient donc aux données facultatives, comme …

```
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
```

> Une table peut aussi être jointe à elle-même : c’est l’auto-jointure. Elle est utile lorsqu’une colonne fait référence à une autre ligne de la même table, comme recommandé_par dans la table membres. Il suffit de donner deux alias différents à la table. Voici, sans doublons et par ordre alphabétique,…

```
SELECT DISTINCT mem1.prénom AS prénom, mem1.nom_famille AS nom 
FROM
membres mem2
INNER JOIN membres mem1
       ON mem1.numéro_membre = mem2.recommandé_par
    ORDER BY nom, prénom
    Limit 5 ;
```


## 2.4.1 Opérations arithmétiques et fonctions d’agrégation

> Tableau 2.4 – Opérations arithmétiques en SQL

```
SELECT count(*) FROM activités;
```

> SELECT left(nom_famille, 1) AS lettre,

```
       count(*) AS nombre
FROM membres
GROUP BY lettre
ORDER BY lettre
LIMIT 5;
```

> Pour obtenir la somme des frais d’entretien mensuels de toutes les activités :

```
SELECT 
   SUM(maintenance_mensuelle)
    FROM activités;
```


## 2.4.2 Fonctions prédéfinies SQL

> SQL définit en plus un grand nombre de fonctions de manipulation de nombres, de chaînes de caractères et de dates, dont EXTRACT, qui extrait une partie d’une date, et date_trunc, qui tronque une date ou un intervalle à une précision donnée :

```
SELECT EXTRACT(DAY FROM TIMESTAMP '2001-02-16 20:38:40');
```

> Voici un exemple qui ramène un intervalle à l’heure près, en mettant à zéro les minutes et les secondes :

```
SELECT date_trunc('hour', INTERVAL '3 days 02:47:33');
```


## 2.4.3 Regroupement avec GROUP BY et HAVING

> L’énoncé GROUP BY combine des lignes similaires, produisant une seule ligne de résultat pour chaque groupe de lignes ayant les mêmes valeurs, pour chaque colonne répertoriée dans l’énoncé. Par exemple, pour compter le nombre de recommandations faites par chaque membre, triées par numéro de membre :

```
SELECT recommandé_par, count(*)
FROM membres
WHERE recommandé_par is not null
GROUP BY recommandé_par
ORDER BY recommandé_par ;
```


## 2.4.4 Test d’ensemble non vide (EXISTS)

> En pratique, on corrèle la sous-requête à la requête principale. La requête suivante liste les membres qui ont réservé au moins une fois le terrain de squash (activité 6) :

```
SELECT m.prénom, m.nom_famille
FROM membres m
WHERE EXISTS (SELECT *
              FROM réservations r
              WHERE r.numéro_membre = m.numéro_membre
                AND r.numéro_activité = 6)
ORDER BY m.nom_famille;
```


## 2.4.5 Test de double (UNIQUE)

> La norme SQL définit le prédicat UNIQUE, qui retourne VRAI lorsque la sous-requête qui le suit ne produit aucune ligne en double. Il permet par exemple de vérifier qu’aucun membre n’a deux réservations qui commencent exactement au même moment. Dans la norme, la requête s’écrirait ainsi :

```
SELECT m.numéro_membre, m.nom_famille
FROM   membres m
WHERE  UNIQUE (SELECT r.temps_de_début
               FROM   réservations r
               WHERE  r.numéro_membre = m.numéro_membre);
```

> Attention : ce prédicat est très peu implémenté. PostgreSQL 18, comme la plupart des SGBD courants, ne le prend pas en charge : il retourne l’erreur « UNIQUE predicate is not yet implemented ». Il faut donc savoir l’exprimer autrement. La façon la plus lisible consiste à regrouper les lignes et à ga…

```
SELECT   numéro_membre, temps_de_début, COUNT(*) AS nb
FROM     réservations
GROUP BY numéro_membre, temps_de_début
HAVING   COUNT(*) > 1;
```

> Lorsque cette vérification doit être garantie en permanence, il est préférable de ne pas la confier aux requêtes, mais au schéma lui-même, à l’aide d’une contrainte d’unicité. Le SGBD refusera alors toute insertion qui créerait un double :

```
ALTER TABLE réservations
ADD CONSTRAINT réservation_unique
UNIQUE (numéro_membre, temps_de_début);
```

> Avec les données du club, cette commande échoue toutefois : l’invité, qui porte le numéro de membre 0, a souvent plusieurs réservations au même moment, et PostgreSQL refuse de créer l’index d’unicité (« could not create unique index »). Il faut alors restreindre la règle aux membres, au moyen d’un i…

```
CREATE UNIQUE INDEX réservation_unique
    ON réservations (numéro_membre, temps_de_début)
    WHERE numéro_membre <> 0;
```


## 2.4.6 Quantificateurs (ALL, SOME/ANY)

> Par exemple, pour trouver l’activité dont l’entretien mensuel est le plus coûteux, on cherche l’activité dont la maintenance est supérieure ou égale à celle de toutes les activités :

```
SELECT nom, maintenance_mensuelle
FROM   activités
WHERE  maintenance_mensuelle >= ALL (SELECT maintenance_mensuelle
                                     FROM   activités);
```

> Avec ANY, on peut lister les activités dont le coût pour les invités dépasse le coût pour les membres d’au moins une activité :

```
SELECT nom, coût_pour_invités
FROM   activités
WHERE  coût_pour_invités > ANY (SELECT coût_pour_membre
                                FROM   activités);
```


## 2.4.7 Test d’inclusion entre deux tables et division

> La première formulation suit la logique « il n’existe aucune activité que ce membre n’ait pas réservée ». Elle utilise deux NOT EXISTS imbriqués :

```
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
```

> La seconde formulation compte : un membre a réservé toutes les activités si le nombre d’activités distinctes qu’il a réservées est égal au nombre total d’activités. Elle est souvent plus facile à lire et à optimiser :

```
SELECT   r.numéro_membre
FROM     réservations r
GROUP BY r.numéro_membre
HAVING   COUNT(DISTINCT r.numéro_activité) =
         (SELECT COUNT(*) FROM activités);
```

> Le test d’inclusion peut aussi s’écrire avec l’opérateur ensembliste EXCEPT vu à la section 2.3.9 : l’ensemble des activités moins l’ensemble des activités réservées par le membre doit être vide. La requête suivante vérifie ce test pour le membre numéro 1 :

```
SELECT numéro_activité FROM activités
EXCEPT
SELECT numéro_activité FROM réservations
WHERE  numéro_membre = 1;
```


## 2.4.8 SELECT imbriqué dans le FROM (table dérivée)

> La table dérivée dans le FROM nécessite l’utilisation des deux colonnes numéro_membre et numéro_activité, car c’est la paire (membre, activité) qui doit disparaître après la date. Par contre, seul le numéro_membre est demandé dans le résultat, et DISTINCT évite qu’un membre apparaisse plusieurs fois…

```
référence ::= nom_table [AS alias]
  | référence [INNER | {LEFT | RIGHT | FULL} [OUTER]]
      JOIN référence ON condition
  | référence NATURAL [INNER | {LEFT | RIGHT | FULL} [OUTER]]
      JOIN référence
  | référence CROSS JOIN référence
  | (requête_SELECT) AS alias

```


## 2.4.9 Opérations sur les chaînes de caractères

> La section 2.3.3 a présenté l’opérateur LIKE. Un point mérite d’être connu : son usage des index. Un motif qui commence par une partie fixe, comme 'Tennis%', peut utiliser un index B-arbre si la base utilise la collation C ou si l’index est créé avec la classe d’opérateurs text_pattern_ops ; un moti…

```
SELECT * 
FROM activités
WHERE nom
LIKE '___________T______2';
```

> Ces fonctions complètent une chaîne, à droite (RPAD) ou à gauche (LPAD), jusqu’à une longueur donnée avec le caractère choisi ; si la chaîne est plus longue, elle est tronquée, comme le montre la figure 2.36.

```
SELECT RPAD(nom,10,'+') 
FROM activités
```

> La fonction SUBSTRING extrait une partie d’une chaîne à partir d’une position donnée et pour une longueur déterminée. En SQL, la première position d’une chaîne est 1, et non 0 comme dans plusieurs langages de programmation. La forme générale est SUBSTRING(chaîne FROM début FOR longueur); PostgreSQL …

```
SELECT nom_famille,
       SUBSTRING(codepostal FROM 1 FOR 3) AS région
FROM   membres;
```

> La fonction POSITION retourne la position de la première occurrence d’une sous-chaîne, ou 0 si elle est absente. Combinée à SUBSTRING, elle permet de découper une chaîne autour d’un séparateur, par exemple pour isoler le premier mot du nom d’une activité :

```
SELECT nom,
       SUBSTRING(nom FROM 1
                 FOR POSITION(' ' IN nom) - 1) AS premier_mot
FROM   activités
WHERE  POSITION(' ' IN nom) > 0;
```

> L’opérateur SIMILAR TO se situe entre LIKE et les expressions régulières complètes. Il accepte les caractères % et _ de LIKE, ainsi que l’alternative |, les classes de caractères entre crochets et les répétitions * et +. Comme LIKE, il doit correspondre à la chaîne entière. La requête suivante trouv…

```
SELECT nom
FROM   activités
WHERE  nom SIMILAR TO '%(Tennis|Squash)%';
```

> La fonction TRANSLATE remplace des caractères un à un : chaque caractère de la deuxième chaîne est remplacé par le caractère situé à la même position dans la troisième chaîne. Les caractères sans correspondant sont supprimés. Elle est utile pour normaliser des données saisies de façon incohérente, p…

```
SELECT téléphone,
       TRANSLATE(téléphone, '()- ', '') AS téléphone_normalisé
FROM   membres;
```

> La fonction REGEXP_REPLACE remplace les parties d’une chaîne qui correspondent à une expression régulière. Le quatrième paramètre facultatif 'g' (global) demande de remplacer toutes les occurrences et non seulement la première. La requête suivante garde seulement les chiffres du numéro de téléphone,…

```
SELECT REGEXP_REPLACE(
         REGEXP_REPLACE(téléphone, '[^0-9]', '', 'g'),
         '^([0-9]{3})([0-9]{3})([0-9]{4})$',
         '(\1) \2-\3') AS téléphone_formaté
FROM   membres;
```


## 2.4.10 Les expressions de table communes (WITH et WITH RECURSIVE)

> Par exemple, pour lister les activités dont le revenu total dépasse la moyenne des revenus de toutes les activités, on calcule d’abord le revenu de chaque activité, puis on compare à la moyenne. Dans le schéma du Club Sportif, la colonne emplacement contient le nombre de demi-heures réservées et l’i…

```
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
```

> La requête suivante remonte la chaîne de recommandation du membre numéro 27 : qui l’a recommandé, qui a recommandé cette personne, et ainsi de suite.

```
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
```


## 2.5.2 Modification de lignes dans une table (UPDATE)

> Nous avons commis une erreur lors de l’introduction des données relatives au deuxième terrain de tennis. La mise de fonds initiale était de 10000 au lieu de 8000.

```
UPDATE activités 
SET mise_de_fonds_initiale = 10000       
WHERE numéro_activité = 1;
```

> Vous pouvez aussi mettre à jour une donnée à partir des données d’une autre colonne. Par exemple, pour que le deuxième terrain de tennis coûte 10 % de plus que le premier, sans écrire de valeur constante : 

```
UPDATE activités act 
SET coût_pour_membre = (SELECT coût_pour_membre * 1.1
               FROM activités 
               WHERE numéro_activité = 0),
    coût_pour_invités = (SELECT coût_pour_invités * 1.1
               FROM activités 
               WHERE numéro_activité = 0)
    
WHERE act.numéro_activité = 1;
```


## 2.5.3 Suppression de lignes dans une table (DELETE)

> Nous voulons supprimer de notre base de données le membre 37, qui n’a jamais effectué de réservation. Comment y parvenir ?

```
DELETE FROM membres WHERE numéro_membre = 37 ;
```

> Essayons maintenant d’être plus généraux et de supprimer d’un seul coup tous les membres qui n’ont jamais fait de réservation. Pour ce faire, il suffit de remplacer la valeur constante de la clause WHERE par une sous-requête qui retourne les numéros des membres présents dans la table réservations : 

```
DELETE FROM membres
WHERE numéro_membre 
NOT IN (SELECT numéro_membre FROM réservations) ;
```
