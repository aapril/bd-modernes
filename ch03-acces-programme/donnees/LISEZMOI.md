# Données du chapitre 3

Ce dossier est visible dans le conteneur pg-club sous le chemin `/donnees` (voir ch02-postgresql/compose.yaml).

| Fichier | Contenu | Utilisé à |
|---|---|---|
| `vins.csv` | 25 millésimes de Bordeaux, 1952 à 1978 (Ashenfelter, Ashmore et Lalonde, 1995) | section 3.10.2, chapitre 10 |
| `Films.json` | 631 films, objet `films` contenant le tableau `film` | section 3.10.3, chapitre 11 |
| `clients_utf8.xml` | 21 550 clients fictifs, avec carte de crédit et forfait | section 3.10.4, étude de cas 3.11 |
| `films_utf8.xml` | les 631 films, avec genres, pays, scénaristes, rôles et bandes-annonces | étude de cas 3.11 |
| `personnes_utf8.xml` | 4 549 acteurs et réalisateurs | étude de cas 3.11 |
| `nouveaux.csv` | nouveaux membres, dont certaines lignes invalides | exercice 3.6 |
| `*_utf8.json` | les trois fichiers XML convertis en JSON, pour des essais avec MongoDB | facultatif |

Le script de l'étude de cas ne charge que les quatre derniers chiffres de la carte et ne charge pas le mot de passe.
