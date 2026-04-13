# Étape 1 — Build avec Maven
FROM maven:3.9-eclipse-temurin-11 AS builder
WORKDIR /app
COPY pom.xml .

# 2. IMPORTANT : Pour que go-offline fonctionne avec Avro, 
COPY src/main/avro ./src/main/avro

# Télécharger les dépendances en cache séparé (optimisation Docker layer)
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

# Étape 2 — Image finale légère
FROM eclipse-temurin:11-jre
WORKDIR /app
COPY --from=builder /app/target/producer_schema-1.0-SNAPSHOT-jar-with-dependencies.jar producer.jar
COPY src/main/resources/producer.properties producer.properties
CMD ["java", "-jar", "producer.jar"]
