#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre12.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre12.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre12.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 12 : Kafka 4.4 ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch12-kafka && docker compose down -v >/dev/null 2>&1; docker compose up -d
attendre "docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list"
K="docker exec -i kafka bash -c"
bloc "12-7 12.3 Installer Kafka et premiers pas"
echo '$ ./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic passages --partitions 6 --replication-factor 1'; $K 'cd /opt/kafka/bin && ./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic passages --partitions 6 --replication-factor 1'
echo '$ ./kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic passages'; $K 'cd /opt/kafka/bin && ./kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic passages'
bloc "12-8 12.3 Installer Kafka et premiers pas"
echo '$ ./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic passages --reader-property parse.key=true --reader-property key.separator=:'; printf '27:{"membre":27,"site":"Centre-ville","sens":"ENTREE"}\n44:{"membre":44,"site":"Plateau","sens":"ENTREE"}\n' | $K 'cd /opt/kafka/bin && ./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic passages --reader-property parse.key=true --reader-property key.separator=:'
echo '$ ./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic passages --group tableau-de-bord --from-beginning --formatter-property print.key=true --timeout-ms 10000'; $K 'cd /opt/kafka/bin && ./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic passages --group tableau-de-bord --from-beginning --formatter-property print.key=true --timeout-ms 10000'
bloc "12-9 12.3 Installer Kafka et premiers pas"
echo '$ ./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group tableau-de-bord'; $K 'cd /opt/kafka/bin && ./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group tableau-de-bord'
bloc "Compilation Java (pom.xml du dépôt)"
(command -v mvn >/dev/null && cd java && mvn -q -DskipTests compile && echo "Compilation réussie") || echo "Maven absent : étape sautée"
cd ..
