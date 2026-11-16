SELECT numéro_activité, sum(emplacement) AS "Réservations Totales" FROM réservations GROUP BY numéro_activité HAVING sum(emplacement) > 1000 ORDER BY numéro_activité;
