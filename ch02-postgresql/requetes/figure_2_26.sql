SELECT DISTINCT mem1.prénom AS prénom, mem1.nom_famille AS nom FROM membres mem2 INNER JOIN membres mem1 ON mem1.numéro_membre = mem2.recommandé_par ORDER BY nom, prénom LIMIT 5;
