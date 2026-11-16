#!/usr/bin/env bash
# Vérifie que la base « club » donne les résultats présentés dans le chapitre 2.
# Usage : ./verifier.sh   (le conteneur pg-club doit être démarré)
cd "$(dirname "$0")"
CONTENEUR=${CONTENEUR:-pg-club}
ok=0; ecart=0
for f in requetes/*.sql; do
  b=$(basename "$f" .sql)
  obtenu=$(docker exec -i "$CONTENEUR" psql -U postgres -d club -A -F'|' -P footer=off < "$f" 2>&1)
  if [ "$obtenu" == "$(cat attendu/$b.txt)" ]; then ok=$((ok+1)); echo "OK      $b"
  else ecart=$((ecart+1)); echo "ÉCART   $b"; diff <(echo "$obtenu") "attendu/$b.txt" | head -5; fi
done
echo "Résultat : $ok vérifications réussies, $ecart écarts."
[ $ecart -eq 0 ]
