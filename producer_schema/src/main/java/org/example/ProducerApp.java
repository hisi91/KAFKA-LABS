package org.example;

import org.apache.kafka.clients.producer.*;
import java.io.InputStream;
import java.util.Properties;
import java.util.Random;

public class ProducerApp {
    public static void main(String[] args) throws Exception {
        Properties configs = new Properties();
        try (InputStream in = ProducerApp.class.getClassLoader().getResourceAsStream("producer.properties")) {
            configs.load(in);
        }

        KafkaProducer<String, User> producer = new KafkaProducer<>(configs);

        User user = new User("John Doe" , 30);

        ProducerRecord<String, User> record = new ProducerRecord<>("users", user.getName().toString(), user);
        producer.send(record);
        producer.close();
    }
}