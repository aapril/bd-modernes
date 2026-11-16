SELECT nom, CASE WHEN (maintenance_mensuelle > 100) THEN 'chère' ELSE 'économique' END AS coût FROM activités;
