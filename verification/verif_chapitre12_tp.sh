#!/usr/bin/env bash
# Vérifie la base de code du travail pratique de la section 12.8 (dossier ch12-kafka/tp).
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre12_tp.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre12_tp.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 12, travail pratique ; $(date)"; echo "# $(uname -a)"; docker --version
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
K=/opt/kafka/bin
(cd ch12-kafka && docker compose stop >/dev/null 2>&1)
cd ch12-kafka/tp

bloc "Compilation du projet Java (Maven dans un conteneur, JDK 21)"
docker run --rm -v "$PWD":/w -v bdm-m2:/root/.m2 -w /w maven:3.9-eclipse-temurin-21 \
  mvn -B -q -DskipTests package && echo "COMPILATION RÉUSSIE"

bloc "Démarrage du système (docker compose up -d)"
docker compose down -v >/dev/null 2>&1
docker compose up -d
for i in $(seq 1 60); do docker exec broker $K/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1 && break; sleep 2; done
docker compose ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}"
for c in order_generator transporter_generator shipping_listener; do
  echo "$c : architecture de l'image = $(docker image inspect --format '{{.Architecture}}' mathieu2525/org.etsmtl.ind500.tp3:latest 2>/dev/null)"; break
done
echo "Attente de 60 secondes pour laisser les générateurs produire des événements..."; sleep 60

bloc "Sujets et nombre de messages"
docker exec broker $K/kafka-topics.sh --bootstrap-server localhost:9092 --list
for t in newOrder orderReview transporterLocation; do
  n=$(docker exec broker $K/kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic $t 2>/dev/null | awk -F: '{s+=$3} END {print s+0}')
  echo "$t : $n messages"
done

bloc "Exemples de messages (un par sujet)"
for t in newOrder orderReview transporterLocation; do
  echo "--- $t"
  docker exec broker $K/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic $t \
    --from-beginning --max-messages 1 --property print.key=true --timeout-ms 15000 2>/dev/null | cut -c1-400
done

bloc "Lecture des flux avec les modèles fournis (Kafka Streams, 30 secondes)"
W="$HOME/.bdm-verif-tp"; rm -rf "$W"; mkdir -p "$W"; cp -R pom.xml src "$W/"
# Le programme tourne dans un conteneur relié au réseau du système : il joint le serveur par broker:29092.
sed -i.bak 's#"localhost:9092"#"broker:29092"#' "$W/src/main/java/org/etsmtl/ind500/configs/Config.java"
mkdir -p "$W/src/main/java/verif"
cat > "$W/src/main/java/verif/VerifierFlux.java" <<'FIN_JAVA'
package verif;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.Consumed;
import org.etsmtl.ind500.configs.Config;
import org.etsmtl.ind500.models.Order;
import org.etsmtl.ind500.models.OrderReview;
import org.etsmtl.ind500.models.TransporterLocation;
import org.etsmtl.ind500.utils.EtsKafkaStreams;
import java.util.concurrent.atomic.AtomicInteger;

public class VerifierFlux {
    public static void main(String[] args) throws Exception {
        AtomicInteger commandes = new AtomicInteger(), articles = new AtomicInteger(),
                      avis = new AtomicInteger(), positions = new AtomicInteger();
        StreamsBuilder b = new StreamsBuilder();
        b.stream(Config.NEW_ORDER_TOPIC, Consumed.with(Serdes.String(), Order.getSerde()))
         .foreach((k, o) -> { commandes.incrementAndGet(); articles.addAndGet(o.getItems().size()); });
        b.stream(Config.ORDER_REVIEW_TOPIC, Consumed.with(Serdes.String(), OrderReview.getSerde()))
         .foreach((k, r) -> avis.incrementAndGet());
        b.stream(Config.TRANSPORTER_LOCATION_TOPIC, Consumed.with(Serdes.String(), TransporterLocation.getSerde()))
         .foreach((k, t) -> positions.incrementAndGet());
        KafkaStreams s = EtsKafkaStreams.createDefaultKafkaStreams(b, "verif-livre-" + System.currentTimeMillis(), "verif", true);
        s.start();
        Thread.sleep(30000);
        s.close();
        System.out.println("RÉSULTAT commandes=" + commandes + " articles=" + articles
                + " avis=" + avis + " positions=" + positions);
    }
}
FIN_JAVA
NET=$(docker inspect broker --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
docker run --rm --network "$NET" -v "$W":/w -v bdm-m2:/root/.m2 -w /w maven:3.9-eclipse-temurin-21 \
  mvn -B -q -DskipTests compile exec:java -Dexec.mainClass=verif.VerifierFlux 2>&1 | grep -v "^SLF4J\|DEBUG" | tail -25
rm -rf "$W"

bloc "Aller-retour avec shipping_listener (demande, soumission, confirmation)"
CMD=$(docker exec broker $K/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic newOrder --from-beginning --max-messages 1 --timeout-ms 15000 2>/dev/null)
TR=$(docker exec broker $K/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic transporterLocation --from-beginning --max-messages 1 --timeout-ms 15000 2>/dev/null)
OID=$(printf '%s' "$CMD" | python3 -c "import sys,json; print(json.load(sys.stdin)['uuid'])")
TID=$(printf '%s' "$TR" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "commande : $OID ; livreur : $TID"
REQ="{\"orderId\":\"$OID\",\"transporterId\":\"$TID\",\"deliverySpecs\":{\"totalWeight\":4.5,\"maxDepth\":8,\"maxWidth\":8,\"maxHeight\":30}}"
echo "$OID|$REQ" | docker exec -i broker $K/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic shippingQuoteRequest --property parse.key=true --property key.separator='|'
sleep 10
echo "--- réponse dans shippingQuoteResponse"
REP=$(docker exec broker $K/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic shippingQuoteResponse --from-beginning --max-messages 1 --timeout-ms 20000 2>/dev/null)
echo "$REP"
PRIX=$(printf '%s' "$REP" | python3 -c "import sys,json; print(json.load(sys.stdin)['quotePrice'])" 2>/dev/null)
CONF="{\"orderId\":\"$OID\",\"transporterId\":\"$TID\",\"quotePrice\":${PRIX:-0},\"quoteStatus\":\"ACCEPT\"}"
echo "$OID|$CONF" | docker exec -i broker $K/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic shippingQuoteConfirmation --property parse.key=true --property key.separator='|'
sleep 5
echo "--- console de shipping_listener (dernières lignes)"
docker logs --tail 15 shipping_listener 2>&1

bloc "Arrêt"
docker compose down -v
cd ../..
