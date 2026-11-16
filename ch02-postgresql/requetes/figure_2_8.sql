SELECT numéro_activité, nom, coût_pour_membre, maintenance_mensuelle FROM activités WHERE coût_pour_membre > 0 AND (coût_pour_membre < maintenance_mensuelle/50.0);
