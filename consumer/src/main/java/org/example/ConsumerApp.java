package org.example;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import java.io.InputStream;
import java.time.Duration;
import java.util.List;
import java.util.Properties;

public class ConsumerApp {
    public static void main(String[] args) throws Exception {
        String topicName = "vehicle-count";

        Properties configs = new Properties();
        try (InputStream in = ConsumerApp.class.getClassLoader().getResourceAsStream("consumer.properties")) {
            configs.load(in);
        }

        try (KafkaConsumer<String, String> kafkaConsumer = new KafkaConsumer<>(configs)) {
            kafkaConsumer.subscribe(List.of(topicName));

            while (true) {
                ConsumerRecords<String, String> consumerRecords = kafkaConsumer.poll(Duration.ofMillis(1000));
                for (ConsumerRecord<String, String> record : consumerRecords) {
                    System.out.println("Consumed message: (" + record.key() + ", " + record.value() + ")" +
                        " --> partition=" + record.partition() + " offset=" + record.offset());
                }
            }
        }
    }
}