# Chapitre 12 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 12.3 Installer Kafka et premiers pas

> L’image Docker officielle démarre un courtier unique en mode KRaft, suffisant pour les exercices. Le fichier compose.yaml du dossier ch12-kafka démarre le courtier, nommé kafka, sur le port 9092 :

```
% cd bd-modernes/ch12-kafka
% docker compose up -d
```

> Sans le dépôt, la commande suivante démarre le même courtier :

```
% docker run -d --name kafka -p 9092:9092 apache/kafka:4.4.0
```

> La commande suivante liste les sujets du courtier ; sur un courtier neuf, la liste est vide et la commande se termine sans erreur :

```
% docker exec -it kafka /opt/kafka/bin/kafka-topics.sh \
       --bootstrap-server localhost:9092 --list
```

> Les sujets et les messages des sections 12.3 à 12.5 sont créés par les commandes et les programmes du chapitre. Le travail pratique de la section 12.8 utilise sa propre base de code, dans le dossier ch12-kafka/tp du dépôt : un projet Maven de départ et un fichier docker-compose.yml qui démarre un au…

```
% cd java && mvn -q compile
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker compose down -v
```

> Le travail pratique se nettoie de la même façon avec son propre fichier docker-compose.yml (section 12.8.4).

```
% docker exec -it kafka bash
$ cd /opt/kafka/bin
```

> Les scripts fournis avec Kafka permettent de créer un sujet, d’y écrire et de le lire. Créons un sujet de six partitions pour les passages aux tourniquets du Club Sportif (chapitre 9) :

```
$ ./kafka-topics.sh --bootstrap-server localhost:9092 \
      --create --topic passages --partitions 6 \
      --replication-factor 1
$ ./kafka-topics.sh --bootstrap-server localhost:9092 \
      --describe --topic passages
```

> Dans un deuxième terminal, démarrez un consommateur qui affiche les clés ; puis, dans le premier, publiez quelques messages en séparant la clé de la valeur par un deux-points :

```
$ ./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
      --topic passages --group tableau-de-bord \
      --from-beginning --formatter-property print.key=true

$ ./kafka-console-producer.sh --bootstrap-server localhost:9092 \
      --topic passages --reader-property parse.key=true \
      --reader-property key.separator=:
> 27:{"membre":27,"site":"Centre-ville","sens":"ENTREE"}
> 44:{"membre":44,"site":"Plateau","sens":"ENTREE"}
```

> La commande suivante montre, pour chaque partition, le décalage atteint par le groupe et son retard :

```
$ ./kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
      --describe --group tableau-de-bord
```


## 12.4 Produire et consommer en Java

> La bibliothèque cliente officielle de Kafka est écrite en Java ; des clients existent pour la plupart des langages. Un producteur se configure avec l’adresse de la grappe et des sérialiseurs pour la clé et la valeur. L’envoi est asynchrone : la fonction de rappel est appelée lorsque le courtier a co…

```
Properties p = new Properties();
p.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
p.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
      StringSerializer.class);
p.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
      StringSerializer.class);
p.put(ProducerConfig.ACKS_CONFIG, "all");
p.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);

try (KafkaProducer<String, String> prod = new KafkaProducer<>(p)) {
  String json = "{\"membre\":27,\"site\":\"Centre-ville\"}";
  prod.send(new ProducerRecord<>("passages", "27", json),
      (meta, err) -> {
        if (err != null) err.printStackTrace();
        else System.out.printf("partition %d, décalage %d%n",
                               meta.partition(), meta.offset());
      });
}
```

> Un consommateur s’abonne à un ou plusieurs sujets et appelle poll en boucle. Dans l’exemple suivant, la validation automatique est désactivée : le décalage est validé seulement après le traitement du lot, ce qui donne la garantie « au moins une fois » :

```
Properties c = new Properties();
c.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
c.put(ConsumerConfig.GROUP_ID_CONFIG, "facturation");
c.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);
c.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
c.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
      StringDeserializer.class);
c.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,
      StringDeserializer.class);

try (KafkaConsumer<String, String> cons = new KafkaConsumer<>(c)) {
  cons.subscribe(List.of("passages"));
  while (true) {
    ConsumerRecords<String, String> lot =
        cons.poll(Duration.ofMillis(500));
    for (ConsumerRecord<String, String> r : lot) {
      traiter(r.key(), r.value());      // doit être idempotent
    }
    cons.commitSync();
  }
}
```


## 12.5.4 Exemple : l’occupation des sites du Club Sportif

> Le Club Sportif veut afficher en temps réel le nombre d’entrées par site, par tranche de cinq minutes, à partir du sujet passages alimenté par les tourniquets. La topologie suivante filtre les entrées, regroupe les passages par site, compte par fenêtre fixe de cinq minutes et publie le résultat dans…

```
Properties props = new Properties();
props.put(StreamsConfig.APPLICATION_ID_CONFIG, "occupation-sites");
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
props.put(StreamsConfig.PROCESSING_GUARANTEE_CONFIG,
          StreamsConfig.EXACTLY_ONCE_V2);

StreamsBuilder sb = new StreamsBuilder();
KStream<String, Passage> passages = sb.stream("passages",
    Consumed.with(Serdes.String(), Passage.serde()));

KTable<Windowed<String>, Long> entrées = passages
    .filter((cle, p) -> "ENTREE".equals(p.sens()))
    .groupBy((cle, p) -> p.site(),
             Grouped.with(Serdes.String(), Passage.serde()))
    .windowedBy(TimeWindows.ofSizeAndGrace(
             Duration.ofMinutes(5), Duration.ofMinutes(1)))
    .count(Materialized.as("entrees-par-site"));

entrées.toStream()
    .map((w, n) -> KeyValue.pair(
             w.key() + "@" + w.window().startTime(), n))
    .to("occupation-5min",
        Produced.with(Serdes.String(), Serdes.Long()));

KafkaStreams app = new KafkaStreams(sb.build(), props);
Runtime.getRuntime().addShutdownHook(new Thread(app::close));
app.start();
```


## 12.5.5 Jointures

> flux-flux : deux événements qui ont la même clé sont associés s’ils se produisent dans une même fenêtre de temps, par exemple une demande de prix et la réponse correspondante reçue dans les deux minutes.

```
KTable<String, Membre> membres = sb.table("membres",
    Consumed.with(Serdes.String(), Membre.serde()));

KStream<String, PassageEnrichi> enrichis = passages
    .selectKey((cle, p) -> String.valueOf(p.membre()))
    .join(membres,
          (p, m) -> new PassageEnrichi(p, m.categorie()),
          Joined.with(Serdes.String(), Passage.serde(),
                      Membre.serde()));
```


## 12.6 Kafka Connect et la capture des données modifiées

> La source la plus importante est la capture des données modifiées (Change Data Capture, CDC), mentionnée au chapitre 10. Le connecteur Debezium lit le journal de transactions de PostgreSQL (le WAL) et publie chaque insertion, modification et suppression comme un événement, sans aucune modification d…

```
{
  "name": "club-postgres",
  "config": {
    "connector.class":
        "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "debezium",
    "database.password": "${file:/secrets/pg.properties:mdp}",
    "database.dbname": "club",
    "plugin.name": "pgoutput",
    "topic.prefix": "club",
    "table.include.list": "public.reservations,public.membres"
  }
}
```


## Nouvelle commande

> Message :

```
{
  "uuid": "55b33d0f-20e5-4901-b9d6-70730a868785",
  "date": "2025-09-08 21:05:41",
  "status": "created",
  "customer": {
    "uniqueId": "0028a7d8db7b0247652509358ad8d755",
    "firstname": "Theo",
    "lastname": "Ramos",
    "phone": "5538-1201",
    "address": "5072 Estrada Vasconcelos",
    "zipcode": "13273",
    "city": "valinhos",
    "state": "SP",
    "location": {
      "latitude": 43.47597956,
      "longitude": 55.0717908
    }
  },
  "items": [
    {
      "qty": 3,
      "product": {
        "category": "alimentos_bebidas",
        "name": "Água Mineral Minalba 500ml",
        "description": "Água mineral natural com sais balanceados.",
        "weight": 1.5,
        "width": 8,
        "height": 30,
        "depth": 8,
        "price": 998.12
      },
      "seller": {
        "uuid": "f3041c2e75ec683697a6a5ea82192210",
        "location": {
          "latitude": -19.89795577,
          "longitude": -46.88598614
        }
      }
    },
    … //Plusieurs éléments
  ]
}
```


## Nouvelle évaluation

> Message :

```
{
  "orderId": "a05fc37f43df506f00a32f1507e4d360",
  "reviewId": "48be8c0d-f5c5-4cfb-8247-ddf6692b8262",
  "title": "Uso básico já",
  "description": "Pouco barulhento: entrega dentro do prazo apenas razoável.",
  "score": 3
}
```


## Localisation des transporteurs

> Message :

```
{
  "id": "58008193fe344e519134311a0e554d5d",
  "state": "SC",
  "city": "abdon batista",
  "location": {
    "latitude": -29.481364540084318,
    "longitude": -69.49404780033086
  }
}
```


## Livraison d’une commande

> Pour chaque nouvelle commande, vous devez trouver le livreur le plus proche à l’aide du flux transporterLocation (constante config.TRANSPORTER_LOCATION_TOPIC). Une fois ce livreur trouvé, demandez-lui une soumission pour connaître le prix de la livraison, en envoyant un message dans le sujet shippin…

```
{
  "orderId": "order’s uuid (32 hex char)",
  "transporterId": "transporter’s uuid (32 hex char)",
  "deliverySpecs": {
    "totalWeight": 99.99,
    "maxDepth": 99.99,
    "maxWidth": 99.99,
    "maxHeight": 99.99
  }
}
```

> Le conteneur shipping_listener lit votre demande et y répond dans le sujet shippingQuoteResponse (constante config.SHIPPING_QUOTE_RESPONSE_TOPIC). Les messages de ce sujet ont la structure suivante :

```
{
  "orderId": "order’s uuid (32 hex char)",
  "transporterId": "transporter’s uuid (32 hex char)",
  "quotePrice": 99.99
}
```

> Pour répondre à la soumission, envoyez un message dans le sujet shippingQuoteConfirmation (constante config.SHIPPING_QUOTE_CONFIRMATION_TOPIC). Le message doit avoir la structure suivante :

```
{
  "orderId": "order’s uuid (32 hex char)",
  "transporterId": "transporter’s uuid (32 hex char)",
  "quotePrice": 99.99,
  "quoteStatus": "ACCEPT|REJECT"
}
```
