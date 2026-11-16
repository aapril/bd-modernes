# Vérification des exemples du livre

Ces scripts exécutent les exemples du livre tels qu’ils sont imprimés et consignent les résultats, pour que l’auteur puisse les comparer au texte.

Prérequis : Docker Desktop démarré (8 Go de mémoire recommandés), Git, Python 3.12, et facultativement Maven (chapitre 12).

```
cd bd-modernes/verification
./verifier_tout.sh        # environ 20 à 30 minutes
```

Un seul chapitre : `./verif_chapitre7.sh`. Les résultats sont écrits dans `resultats_chapitreN.txt`. Le chapitre 9 (HBase) a son propre script dans `ch09-hbase`.
Les conteneurs sont arrêtés après chaque chapitre ; `docker compose down -v` dans chaque dossier les supprime ensuite.
