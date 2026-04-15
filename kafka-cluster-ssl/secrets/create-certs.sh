#!/bin/bash

PASSWORD=confluent

# CA
openssl req -new -x509 \
  -keyout ca.key \
  -out ca.crt \
  -days 365 \
  -subj "/CN=ca" \
  -nodes

# Cert unique pour tous
keytool -genkeypair \
  -alias kafka \
  -keystore kafka.keystore.jks \
  -storepass $PASSWORD \
  -keypass $PASSWORD \
  -dname "CN=localhost" \
  -keyalg RSA

# CSR
keytool -keystore kafka.keystore.jks \
  -alias kafka \
  -certreq \
  -file kafka.csr \
  -storepass $PASSWORD

# Sign
openssl x509 -req \
  -CA ca.crt \
  -CAkey ca.key \
  -in kafka.csr \
  -out kafka.crt \
  -days 365 \
  -CAcreateserial

# Import CA
keytool -keystore kafka.keystore.jks \
  -alias CARoot \
  -import \
  -file ca.crt \
  -storepass $PASSWORD \
  -noprompt

# Import cert
keytool -keystore kafka.keystore.jks \
  -alias kafka \
  -import \
  -file kafka.crt \
  -storepass $PASSWORD \
  -noprompt

# Truststore
keytool -keystore kafka.truststore.jks \
  -alias CARoot \
  -import \
  -file ca.crt \
  -storepass $PASSWORD \
  -noprompt

echo "confluent" > kafka_keystore_creds
echo "confluent" > kafka_truststore_creds