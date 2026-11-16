SELECT prénom, nom_famille, ancienneté FROM membres WHERE ancienneté = (SELECT MAX(ancienneté) FROM membres);
