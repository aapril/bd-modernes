#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre13.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre13.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre13.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 13 : CouchDB ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch13-registre && docker compose down -v >/dev/null 2>&1; docker compose up -d
export C=http://admin:MotDePasse123@localhost:5984
attendre "curl -sf $C/"
bloc "Accueil"; curl -s $C/; echo
bloc "13-11 13.6 CouchDB, une BD documents à révisions"
echo '$ curl $C/'; curl $C/; echo
bloc "13-13 13.6 CouchDB, une BD documents à révisions"
echo '$ curl -X PUT $C/vehicules'; curl -X PUT $C/vehicules; echo
echo '$ curl -X PUT $C/vehicules/5YJ3E1EA7JF000001 -H "Content-Type: application/json" -d '\''{"marque": "Tesla", "annee": 2012, "proprietaire": "Julie"}'\'''; curl -X PUT $C/vehicules/5YJ3E1EA7JF000001 -H "Content-Type: application/json" -d '{"marque": "Tesla", "annee": 2012, "proprietaire": "Julie"}'; echo
bloc "13-14 13.6 CouchDB, une BD documents à révisions"
echo '$ curl -X PUT $C/vehicules/5YJ3E1EA7JF000001 -H "Content-Type: application/json" -d '\''{"_rev": "1-7c4a...", "marque": "Tesla", "annee": 2012, "proprietaire": "Minh"}'\'''; curl -X PUT $C/vehicules/5YJ3E1EA7JF000001 -H "Content-Type: application/json" -d '{"_rev": "1-7c4a...", "marque": "Tesla", "annee": 2012, "proprietaire": "Minh"}'; echo
bloc "13-15 13.6 CouchDB, une BD documents à révisions"
echo '$ curl -X POST $C/vehicules/_index -H "Content-Type: application/json" -d '\''{"index": {"fields": ["proprietaire"]}}'\'''; curl -X POST $C/vehicules/_index -H "Content-Type: application/json" -d '{"index": {"fields": ["proprietaire"]}}'; echo
echo '$ curl -X POST $C/vehicules/_find -H "Content-Type: application/json" -d '\''{"selector": {"proprietaire": "Minh"}, "fields": ["_id", "marque", "annee"]}'\'''; curl -X POST $C/vehicules/_find -H "Content-Type: application/json" -d '{"selector": {"proprietaire": "Minh"}, "fields": ["_id", "marque", "annee"]}'; echo
bloc "Récupération de la révision courante et modification (section 13.6)"
REV=$(curl -s $C/vehicules/5YJ3E1EA7JF000001 | python3 -c "import sys,json;print(json.load(sys.stdin)['_rev'])")
echo "révision : $REV"
curl -s -X PUT $C/vehicules/5YJ3E1EA7JF000001 -H "Content-Type: application/json" -d "{\"_rev\": \"$REV\", \"marque\": \"Tesla\", \"annee\": 2012, \"proprietaire\": \"Minh\"}"; echo
curl -s $C/vehicules/_changes; echo
cd ..
