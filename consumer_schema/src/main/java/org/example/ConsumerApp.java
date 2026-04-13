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

        Properties configs = new Properties();
        try (InputStream in = ConsumerApp.class.getClassLoader().getResourceAsStream("consumer.properties")) {
            configs.load(in);
        }
        try (KafkaConsumer<String, User> consumer = new KafkaConsumer<>(configs)) {
            consumer.subscribe(List.of("users"));

            while (true) {
                ConsumerRecords<String, User> records = consumer.poll(Duration.ofMillis(1000));

                for (ConsumerRecord<String, User> record : records) {
                    System.out.println("Key: " + record.key());
                    System.out.println("Value: " + record.value());
                    System.out.println("Partition: " + record.partition());
                    System.out.println("Offset: " + record.offset());
                    System.out.println("---");
                }
            }
        }
    }
}