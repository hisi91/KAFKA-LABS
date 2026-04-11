#!/bin/bash

# Créer le topic via ZooKeeper
docker run --net=host --rm confluentinc/cp-kafka:7.6.0 \
  kafka-topics --create --topic bar \
  --partitions 3 \
  --replication-factor 3 \
  --bootstrap-server localhost:9092

# Décrire le topic
docker run --net=host --rm confluentinc/cp-kafka:7.6.0 \
  kafka-topics --describe --topic bar \
  --bootstrap-server localhost:9092

# Produire 42 messages
docker run --net=host --rm confluentinc/cp-kafka:7.6.0 bash -c \
  "seq 42 | kafka-console-producer --bootstrap-server localhost:9092 --topic bar \
  && echo 'Produced 42 messages.'"

# Consommer les 42 messages depuis le début
docker run --net=host --rm confluentinc/cp-kafka:7.6.0 \
  kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic bar \
  --from-beginning \
  --max-messages 42 \
  --timeout-ms 5000