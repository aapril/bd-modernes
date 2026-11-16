SELECT left(nom_famille, 1) AS lettre, count(*) AS nombre FROM membres GROUP BY lettre ORDER BY lettre LIMIT 5;
