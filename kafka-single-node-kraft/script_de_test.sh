#!/bin/bash

docker run --net=host --rm confluentinc/cp-kafka:8.2.0 kafka-topics --create --topic foo --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092 
docker run --net=host --rm confluentinc/cp-kafka:8.2.0 kafka-topics --describe --topic foo --bootstrap-server localhost:9092 
docker run --net=host --rm confluentinc/cp-kafka:8.2.0 bash -c "seq 42 | kafka-console-producer --bootstrap-server localhost:9092 --topic foo --timeout 5000 && echo 'Produced 42 messages.'" 
docker run --net=host --rm confluentinc/cp-kafka:8.2.0 kafka-console-consumer --bootstrap-server localhost:9092 --topic foo  --from-beginning --max-messages 42 --timeout 5000