#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre4.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre4.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre4.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 4 : Redis 8.10 ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch04-redis && docker compose down -v >/dev/null 2>&1; docker compose up -d
attendre "docker exec redis redis-cli PING"
bloc "Version et modules"; docker exec redis redis-cli INFO server | grep redis_version; docker exec redis redis-cli MODULE LIST
bloc "4-7 4.4.1 Les chaînes (strings)"
echo '> SET club:nom "Club Sportif de Montréal"'; docker exec -i redis redis-cli <<'FIN'
SET club:nom "Club Sportif de Montréal"
FIN
echo '> GET club:nom'; docker exec -i redis redis-cli <<'FIN'
GET club:nom
FIN
echo '> DEL club:nom'; docker exec -i redis redis-cli <<'FIN'
DEL club:nom
FIN
bloc "4-8 4.4.1 Les chaînes (strings)"
echo '> INCR club:visites:2023-09-14'; docker exec -i redis redis-cli <<'FIN'
INCR club:visites:2023-09-14
FIN
echo '> INCRBY club:visites:2023-09-14 5'; docker exec -i redis redis-cli <<'FIN'
INCRBY club:visites:2023-09-14 5
FIN
bloc "4-9 4.4.1 Les chaînes (strings)"
echo '> SET code:verif:27 "481920" EX 300'; docker exec -i redis redis-cli <<'FIN'
SET code:verif:27 "481920" EX 300
FIN
echo '> TTL code:verif:27'; docker exec -i redis redis-cli <<'FIN'
TTL code:verif:27
FIN
echo '> SET verrou:rapport "srv-2" NX EX 30'; docker exec -i redis redis-cli <<'FIN'
SET verrou:rapport "srv-2" NX EX 30
FIN
echo '> SET verrou:rapport "srv-3" NX EX 30'; docker exec -i redis redis-cli <<'FIN'
SET verrou:rapport "srv-3" NX EX 30
FIN
bloc "4-10 4.4.2 Les tables de hachage (hashes)"
echo '> HSET membre:27 prénom Julie nom Tremblay cp H3C1K3'; docker exec -i redis redis-cli <<'FIN'
HSET membre:27 prénom Julie nom Tremblay cp H3C1K3
FIN
echo '> HGET membre:27 prénom'; docker exec -i redis redis-cli <<'FIN'
HGET membre:27 prénom
FIN
echo '> HINCRBY membre:27 nb_réservations 1'; docker exec -i redis redis-cli <<'FIN'
HINCRBY membre:27 nb_réservations 1
FIN
echo '> HGETALL membre:27'; docker exec -i redis redis-cli <<'FIN'
HGETALL membre:27
FIN
bloc "4-11 4.4.3 Les listes (lists)"
echo '> LPUSH membre:27:historique "tennis" "squash" "piscine"'; docker exec -i redis redis-cli <<'FIN'
LPUSH membre:27:historique "tennis" "squash" "piscine"
FIN
echo '> LRANGE membre:27:historique 0 -1'; docker exec -i redis redis-cli <<'FIN'
LRANGE membre:27:historique 0 -1
FIN
echo '> LTRIM membre:27:historique 0 9'; docker exec -i redis redis-cli <<'FIN'
LTRIM membre:27:historique 0 9
FIN
bloc "4-12 4.4.4 Les ensembles (sets)"
echo '> SADD activité:tennis:inscrits 27 31 44'; docker exec -i redis redis-cli <<'FIN'
SADD activité:tennis:inscrits 27 31 44
FIN
echo '> SADD activité:squash:inscrits 27 44 58'; docker exec -i redis redis-cli <<'FIN'
SADD activité:squash:inscrits 27 44 58
FIN
echo '> SINTER activité:tennis:inscrits activité:squash:inscrits'; docker exec -i redis redis-cli <<'FIN'
SINTER activité:tennis:inscrits activité:squash:inscrits
FIN
echo '> SISMEMBER activité:tennis:inscrits 58'; docker exec -i redis redis-cli <<'FIN'
SISMEMBER activité:tennis:inscrits 58
FIN
bloc "4-13 4.4.5 Les ensembles triés (sorted sets)"
echo '> ZADD classement:2023 12 "membre:27" 30 "membre:44" 7 "membre:58"'; docker exec -i redis redis-cli <<'FIN'
ZADD classement:2023 12 "membre:27" 30 "membre:44" 7 "membre:58"
FIN
echo '> ZINCRBY classement:2023 1 "membre:58"'; docker exec -i redis redis-cli <<'FIN'
ZINCRBY classement:2023 1 "membre:58"
FIN
echo '> ZRANGE classement:2023 0 2 REV WITHSCORES'; docker exec -i redis redis-cli <<'FIN'
ZRANGE classement:2023 0 2 REV WITHSCORES
FIN
echo '> ZREVRANK classement:2023 "membre:27"'; docker exec -i redis redis-cli <<'FIN'
ZREVRANK classement:2023 "membre:27"
FIN
bloc "4-14 4.4.6 Les flux (streams)"
echo '> XADD flux:résa * membre 27 activité 3 action "créée"'; docker exec -i redis redis-cli <<'FIN'
XADD flux:résa * membre 27 activité 3 action "créée"
FIN
echo '> XGROUP CREATE flux:résa compta 0'; docker exec -i redis redis-cli <<'FIN'
XGROUP CREATE flux:résa compta 0
FIN
echo '> XREADGROUP GROUP compta t1 COUNT 10 STREAMS flux:résa >'; docker exec -i redis redis-cli <<'FIN'
XREADGROUP GROUP compta t1 COUNT 10 STREAMS flux:résa >
FIN
echo '> XACK flux:résa compta 1794804737422-0'; docker exec -i redis redis-cli <<'FIN'
XACK flux:résa compta 1794804737422-0
FIN
bloc "4-15 4.5.2 Transactions"
docker exec -i redis redis-cli <<'FIN'
SET activité:3:places 1
WATCH activité:3:places
GET activité:3:places
MULTI
DECR activité:3:places
SADD activité:3:inscrits 58
EXEC
FIN
cd ..
