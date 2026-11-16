#!/usr/bin/env bash
# Exécute toutes les vérifications, puis regroupe les résultats dans resultats_tous.zip.
cd "$(dirname "$0")"
for n in 2 3 4 5 6 7 10 11 12 13; do
  echo ">>> Chapitre $n"; ./verif_chapitre$n.sh > /dev/null 2>&1; echo "    terminé (resultats_chapitre$n.txt)"
  (cd .. && for d in ch*/; do [ -f "$d/compose.yaml" ] && (cd "$d" && docker compose stop >/dev/null 2>&1); done)
done
zip -q resultats_tous.zip resultats_chapitre*.txt && echo "Envoyez le fichier verification/resultats_tous.zip."
