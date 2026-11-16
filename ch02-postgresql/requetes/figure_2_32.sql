SELECT recommandé_par, count(*) FROM membres WHERE recommandé_par is not null GROUP BY recommandé_par ORDER BY recommandé_par;
