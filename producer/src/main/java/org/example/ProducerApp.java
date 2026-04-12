package org.example;

import org.apache.kafka.clients.producer.*;
import java.io.InputStream;
import java.util.Properties;
import java.util.Random;

public class ProducerApp {
    public static void main(String[] args) throws Exception {
        final int NUMBER_OF_RECORD = 1000000;
        final int MIN = 1;
        final int MAX = 500;
        final String topicName = "vehicle-count";

        Properties configs = new Properties();
        try (InputStream in = ProducerApp.class.getClassLoader().getResourceAsStream("producer.properties")) {
            configs.load(in);
        }

        try (KafkaProducer<String, String> kafkaProducer = new KafkaProducer<>(configs)) {
            for (int i = 0; i < NUMBER_OF_RECORD; i++) {
                String key = "sensor-" + i;
                String value = String.valueOf(new Random().nextInt(MAX - MIN) + MIN);

                ProducerRecord<String, String> producerRecord = new ProducerRecord<>(topicName, key, value);
                System.out.println("Produced message: (" + key + ", " + value + ")");
                kafkaProducer.send(producerRecord, ProducerApp::callBack);
                Thread.sleep(1000);
            }
            System.out.println("Produced " + NUMBER_OF_RECORD + " messages.");
        }
    }

    private static void callBack(RecordMetadata recordMetadata, Exception e) {
        if (e != null) {
            System.out.println("Error occurs : " + e.getMessage());
        } else {
            System.out.println("ack --> offset : " + recordMetadata.offset());
        }
    }
}