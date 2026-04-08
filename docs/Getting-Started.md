# Getting Started with CP on Docker

- Overview
- Getting started on Mac / Linux
	- Single node
		- Manually
		- Compose
	- Bridged Network (Not supported or recommended)
- Secure cluster
- Docker on mac ?
- How to develop ?
- How to extend the images ?
- Best Practices
- Caveats


## Single node Kafka

###Using Docker client

1. Install docker

If you have Docker Toolbox you can skip this section.  
If you have the newer Docker for Mac client you need to do the following:

```
docker-machine start default
eval $(docker-machine env default)
```

The `default` is the name of the docker machine on your host.

2. Run Zookeeper

		docker run -d \
			--net=host \
			--name=zookeeper \
			-e ZOOKEEPER_CLIENT_PORT=32181 \
			-e ZOOKEEPER_TICK_TIME=2000 \
			confluentinc/cp-zookeeper:3.0.0
			
	Check the logs to see the server has booted up successfully

		docker logs zookeeper

	You should see this at the end of the log output

		[2016-07-24 05:15:35,453] INFO binding to port 0.0.0.0/0.0.0.0:32181 (org.apache.zookeeper.server.NIOServerCnxnFactory)

		
3. Run Kafka

		docker run -d \
			--net=host \
			--name=kafka \
      		-e KAFKA_ZOOKEEPER_CONNECT=localhost:32181 \
      		-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:29092 \
			confluentinc/cp-kafka:3.0.0

	Check the logs to see the broker has booted up successfully

		docker logs kafka

	You should see this at the end of the log output

		....
		[2016-07-15 23:31:00,295] INFO [Kafka Server 1], started (kafka.server.KafkaServer)
		[2016-07-15 23:31:00,295] INFO [Kafka Server 1], started (kafka.server.KafkaServer) 
		...
		...
		[2016-07-15 23:31:00,349] INFO [Controller 1]: New broker startup callback for 1 (kafka.controller.KafkaController)
		[2016-07-15 23:31:00,349] INFO [Controller 1]: New broker startup callback for 1 (kafka.controller.KafkaController)
		[2016-07-15 23:31:00,350] INFO [Controller-1-to-broker-1-send-thread], Starting  (kafka.controller.RequestSendThread)
		...
				
4. Test that the broker is working fine

	i. Create a topic
		
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 kafka-topics --create --topic foo --partitions 1 --replication-factor 1 --if-not-exists --zookeeper localhost:32181
		
	You should see 
		
		Created topic "foo".	
	
	ii. Verify that the topic is created successfully
	
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 kafka-topics --describe --topic foo --zookeeper localhost:32181
		
	You should see
	
		Topic:foo	PartitionCount:1	ReplicationFactor:1	Configs:
			Topic: foo	Partition: 0	Leader: 1001	Replicas: 1001	Isr: 1001
		
	iii. Generate data
	
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 bash -c "seq 42 | kafka-console-producer --broker-list localhost:29092 --topic foo && echo 'Produced 42 messages.'"
		
	You should see 
	
		Produced 42 messages.
	
	iv. Read back the message using the Console consumer
	
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 kafka-console-consumer --bootstrap-server localhost:29092 --topic foo --new-consumer --from-beginning --max-messages 42
		
	You should see 
	
		1
		....
		42
		Processed a total of 42 messages



###Using docker compose

0. Install compose
1. Clone the repo

		git clone https://github.com/confluentinc/cp-docker-images
		cd cp-docker-images/examples/kafka-single-node
		
2. Start the services

		docker-compose start
		docker-compose run
		
	Make sure the services are up and running
	
		docker-compose ps
		
	You should see
	
		           Name                        Command            State   Ports
		-----------------------------------------------------------------------
		kafkasinglenode_kafka_1       /etc/confluent/docker/run   Up
		kafkasinglenode_zookeeper_1   /etc/confluent/docker/run   Up
		
	Check the zookeeper logs to verify that Zookeeper is healthy
	
		docker-compose log zookeeper | grep -i binding
		
	You should see message like the following 
		
		zookeeper_1  | [2016-07-25 03:26:04,018] INFO binding to port 0.0.0.0/0.0.0.0:32181 (org.apache.zookeeper.server.NIOServerCnxnFactory)
		
			
	Check the kafka logs to verify that broker is healthy
	
		docker-compose log kafka | grep -i started
		
	You should see message like the following 
		
		kafka_1      | [2016-07-25 03:26:06,007] INFO [Kafka Server 1], started (kafka.server.KafkaServer)
		
		
3. Follow section 3 in "Using Docker client" to test the broker.
		
## 3 node Kafka cluster

###Using Docker client
1. Run a 3-node Zookeeper ensemble

		docker run -d \
			--net=host \
			--name=zk-1 \
			-e ZOOKEEPER_SERVER_ID=1 \
			-e ZOOKEEPER_CLIENT_PORT=22181 \
			-e ZOOKEEPER_TICK_TIME=2000 \
			-e ZOOKEEPER_INIT_LIMIT=5 \
			-e ZOOKEEPER_SYNC_LIMIT=2 \
      		-e ZOOKEEPER_SERVERS="localhost:22888:23888;localhost:32888:33888;localhost:42888:43888" \
			confluentinc/cp-zookeeper:3.0.0
			
		docker run -d \
			--net=host \
			--name=zk-2 \
			-e ZOOKEEPER_SERVER_ID=2 \
			-e ZOOKEEPER_CLIENT_PORT=32181 \
			-e ZOOKEEPER_TICK_TIME=2000 \
			-e ZOOKEEPER_INIT_LIMIT=5 \
			-e ZOOKEEPER_SYNC_LIMIT=2 \
      		-e ZOOKEEPER_SERVERS="localhost:22888:23888;localhost:32888:33888;localhost:42888:43888" \
			confluentinc/cp-zookeeper:3.0.0
			
		docker run -d \
			--net=host \
			--name=zk-3 \
			-e ZOOKEEPER_SERVER_ID=3 \
			-e ZOOKEEPER_CLIENT_PORT=42181 \
			-e ZOOKEEPER_TICK_TIME=2000 \
			-e ZOOKEEPER_INIT_LIMIT=5 \
			-e ZOOKEEPER_SYNC_LIMIT=2 \
      		-e ZOOKEEPER_SERVERS="localhost:22888:23888;localhost:32888:33888;localhost:42888:43888" \
			confluentinc/cp-zookeeper:3.0.0
			
	Check the logs to see the broker has booted up successfully

		docker logs zk-1

	You should see messages like this at the end of the log output

		[2016-07-24 07:17:50,960] INFO Created server with tickTime 2000 minSessionTimeout 4000 maxSessionTimeout 40000 datadir /var/lib/zookeeper/log/version-2 snapdir /var/lib/zookeeper/data/version-2 (org.apache.zookeeper.server.ZooKeeperServer)
		[2016-07-24 07:17:50,961] INFO FOLLOWING - LEADER ELECTION TOOK - 21823 (org.apache.zookeeper.server.quorum.Learner)
		[2016-07-24 07:17:50,983] INFO Getting a diff from the leader 0x0 (org.apache.zookeeper.server.quorum.Learner)
		[2016-07-24 07:17:50,986] INFO Snapshotting: 0x0 to /var/lib/zookeeper/data/version-2/snapshot.0 (org.apache.zookeeper.server.persistence.FileTxnSnapLog)
		[2016-07-24 07:17:52,803] INFO Received connection request /127.0.0.1:50056 (org.apache.zookeeper.server.quorum.QuorumCnxManager)
		[2016-07-24 07:17:52,806] INFO Notification: 1 (message format version), 3 (n.leader), 0x0 (n.zxid), 0x1 (n.round), LOOKING (n.state), 3 (n.sid), 0x0 (n.peerEpoch) FOLLOWING (my state) (org.apache.zookeeper.server.quorum.FastLeaderElection)

	Verify that ZK ensemble is ready
		
		for i in 22181 32181 42181; do
		   docker run --net=host --rm confluentinc/cp-zookeeper:3.0.0 bash -c "echo stat | nc localhost $i | grep Mode"
		done
	
	You should see one `leader` and two `follower`
	
		Mode: follower
		Mode: leader
		Mode: follower
		
2. Run a 3 node Kafka cluster

		docker run -d \
			--net=host \
			--name=kafka-1 \
      		-e KAFKA_ZOOKEEPER_CONNECT=localhost:22181,localhost:32181,localhost:42181 \
      		-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:29092 \
			confluentinc/cp-kafka:3.0.0
			
		docker run -d \
			--net=host \
			--name=kafka-2 \
      		-e KAFKA_ZOOKEEPER_CONNECT=localhost:22181,localhost:32181,localhost:42181 \
      		-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:39092 \
			confluentinc/cp-kafka:3.0.0
			
		docker run -d \
			--net=host \
			--name=kafka-3 \
      		-e KAFKA_ZOOKEEPER_CONNECT=localhost:22181,localhost:32181,localhost:42181 \
      		-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:49092 \
			confluentinc/cp-kafka:3.0.0

	Check the logs to see the broker has booted up successfully

		docker logs kafka-1
		docker logs kafka-2
		docker logs kafka-3
		
	You should see start see bootup messages. For example, `docker logs kafka-3 | grep started` shows the following
	
		[2016-07-24 07:29:20,258] INFO [Kafka Server 1003], started (kafka.server.KafkaServer)
		[2016-07-24 07:29:20,258] INFO [Kafka Server 1003], started (kafka.server.KafkaServer)

	You should see the messages like the following on the broker acting as controller.
	
		[2016-07-24 07:29:20,283] TRACE Controller 1001 epoch 1 received response {error_code=0} for a request sent to broker localhost:29092 (id: 1001 rack: null) (state.change.logger)
		[2016-07-24 07:29:20,283] TRACE Controller 1001 epoch 1 received response {error_code=0} for a request sent to broker localhost:29092 (id: 1001 rack: null) (state.change.logger)
		[2016-07-24 07:29:20,286] INFO [Controller-1001-to-broker-1003-send-thread], Starting  (kafka.controller.RequestSendThread)
		[2016-07-24 07:29:20,286] INFO [Controller-1001-to-broker-1003-send-thread], Starting  (kafka.controller.RequestSendThread)
		[2016-07-24 07:29:20,286] INFO [Controller-1001-to-broker-1003-send-thread], Starting  (kafka.controller.RequestSendThread)
		[2016-07-24 07:29:20,287] INFO [Controller-1001-to-broker-1003-send-thread], Controller 1001 connected to localhost:49092 (id: 1003 rack: null) for sending state change requests (kafka.controller.RequestSendThread)	
				
3. Test that the broker is working fine

	i. Create a topic
		
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 kafka-topics --create --topic bar --partitions 3 --replication-factor 3 --if-not-exists --zookeeper localhost:32181
		
	You should see 
		
		Created topic "bar".	
	
	ii. Verify that the topic is created successfully
	
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 kafka-topics --describe --topic bar --zookeeper localhost:32181
		
	You should see
	
		Topic:bar	PartitionCount:3	ReplicationFactor:3	Configs:
		Topic: bar	Partition: 0	Leader: 1003	Replicas: 1003,1002,1001	Isr: 1003,1002,1001
		Topic: bar	Partition: 1	Leader: 1001	Replicas: 1001,1003,1002	Isr: 1001,1003,1002
		Topic: bar	Partition: 2	Leader: 1002	Replicas: 1002,1001,1003	Isr: 1002,1001,1003
		
	iii. Generate data
	
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 bash -c "seq 42 | kafka-console-producer --broker-list localhost:29092 --topic bar && echo 'Produced 42 messages.'"
		
	You should see 
	
		Produced 42 messages.
	
	iv. Read back the message using the Console consumer
	
		docker run --net=host --rm confluentinc/cp-kafka:3.0.0 kafka-console-consumer --bootstrap-server localhost:29092 --topic bar --new-consumer --from-beginning --max-messages 42
		
	You should see 
	
		1
		4
		7
		10
		13
		16
		....
		41
		Processed a total of 42 messages

###Using docker compose

0. Install compose
1. Clone the repo

		git clone https://github.com/confluentinc/cp-docker-images
		cd cp-docker-images/examples/kafka-cluster
		
2. Start the services

		docker-compose start
		docker-compose run
		
	Make sure the services are up and running
	
		docker-compose ps
		
	You should see
	
	           Name                       Command            State   Ports
		----------------------------------------------------------------------
		kafkacluster_kafka-1_1       /etc/confluent/docker/run   Up
		kafkacluster_kafka-2_1       /etc/confluent/docker/run   Up
		kafkacluster_kafka-3_1       /etc/confluent/docker/run   Up
		kafkacluster_zookeeper-1_1   /etc/confluent/docker/run   Up
		kafkacluster_zookeeper-2_1   /etc/confluent/docker/run   Up
		kafkacluster_zookeeper-3_1   /etc/confluent/docker/run   Up
		
	Check the zookeeper logs to verify that Zookeeper is healthy. For example, for service zookeeper-1
	
		docker-compose log zookeeper-1
		
	You should see messages like the following 
		
		zookeeper-1_1  | [2016-07-25 04:58:12,901] INFO Created server with tickTime 2000 minSessionTimeout 4000 maxSessionTimeout 40000 datadir /var/lib/zookeeper/log/version-2 snapdir /var/lib/zookeeper/data/version-2 (org.apache.zookeeper.server.ZooKeeperServer)
		zookeeper-1_1  | [2016-07-25 04:58:12,902] INFO FOLLOWING - LEADER ELECTION TOOK - 235 (org.apache.zookeeper.server.quorum.Learner)
	
	Verify that ZK ensemble is ready
		
		for i in 22181 32181 42181; do
		   docker run --net=host --rm confluentinc/cp-zookeeper:3.0.0 bash -c "echo stat | nc localhost $i | grep Mode"
		done
	
	You should see one `leader` and two `follower`
	
		Mode: follower
		Mode: leader
		Mode: follower
			
	Check the logs to see the broker has booted up successfully

		docker-compose logs kafka-1
		docker-compose logs kafka-2
		docker-compose logs kafka-3
		
	You should see start see bootup messages. For example, `docker-compose logs kafka-3 | grep started` shows the following
	
		
		kafka-3_1      | [2016-07-25 04:58:15,189] INFO [Kafka Server 3], started (kafka.server.KafkaServer)
		kafka-3_1      | [2016-07-25 04:58:15,189] INFO [Kafka Server 3], started (kafka.server.KafkaServer)

	You should see the messages like the following on the broker acting as controller.
	
		(Tip: `docker-compose log | grep controller` makes it easy to grep through logs for all services.)
	
		kafka-3_1      | [2016-07-25 04:58:15,369] INFO [Controller-3-to-broker-2-send-thread], Controller 3 connected to localhost:29092 (id: 2 rack: null) for sending state change requests (kafka.controller.RequestSendThread)
		kafka-3_1      | [2016-07-25 04:58:15,369] INFO [Controller-3-to-broker-2-send-thread], Controller 3 connected to localhost:29092 (id: 2 rack: null) for sending state change requests (kafka.controller.RequestSendThread)
		kafka-3_1      | [2016-07-25 04:58:15,369] INFO [Controller-3-to-broker-1-send-thread], Controller 3 connected to localhost:19092 (id: 1 rack: null) for sending state change requests (kafka.controller.RequestSendThread)
		kafka-3_1      | [2016-07-25 04:58:15,369] INFO [Controller-3-to-broker-1-send-thread], Controller 3 connected to localhost:19092 (id: 1 rack: null) for sending state change requests (kafka.controller.RequestSendThread)
		kafka-3_1      | [2016-07-25 04:58:15,369] INFO [Controller-3-to-broker-1-send-thread], Controller 3 connected to localhost:19092 (id: 1 rack: null) for sending state change requests (kafka.controller.RequestSendThread)	
		
3. Follow section 3 in "Using Docker client" to test the broker.



## 3 node Kafka cluster with SSL

## 3 node Kafka cluster with SASL/SSL and Kerberos

## External volumes for data for ZK and Kafka

## Using JMX

How to get some data ?

Example of JMXTrans + Influx + Grafana
	
## Changing logging level