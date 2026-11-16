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
