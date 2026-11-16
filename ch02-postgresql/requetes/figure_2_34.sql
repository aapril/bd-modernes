SELECT numéro_activité, nom, maintenance_mensuelle FROM activités WHERE EXISTS (SELECT recommandé_par FROM membres WHERE numéro_membre = 10);
