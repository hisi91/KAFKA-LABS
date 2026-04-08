# 📊 Kafka Confluent Labs - Administration

Ce repository contient une série de labs pratiques autour de l’administration de Apache Kafka.  
Il est conçu pour apprendre à installer, configurer, monitorer et administrer un cluster Kafka dans un contexte proche de la production.


## 🧱 Architecture du Lab

Le lab repose généralement sur une architecture de base sur de docker compose:

- 3 brokers Kafka
- 3 nœuds ZooKeeper
- 1 node utilitaire (monitoring & outils)

Stack de monitoring :

- Prometheus
- Grafana
- Alertmanager
- JMX Exporter

---

# 📊 Kafka Labs - Administration

![GitHub repo size](https://img.shields.io/github/repo-size/hisi91/KAFKA-LABS)
![GitHub stars](https://img.shields.io/github/stars/hisi91/KAFKA-LABS?style=social)
![GitHub forks](https://img.shields.io/github/forks/hisi91/KAFKA-LABS?style=social)
![GitHub issues](https://img.shields.io/github/issues/hisi91/KAFKA-LABS)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 🚀 Overview

Ce repository propose une série de **labs pratiques pour maîtriser l’administration de Apache Kafka** dans un environnement proche de la production.

👉 Objectif : passer de **0 à Kafka Admin opérationnel**

---

## 🧱 Architecture Kafka (Lab)

### 🔷 Diagramme (Mermaid)

```mermaid
flowchart LR
    subgraph Zookeeper Cluster
        Z1[Zookeeper 1]
        Z2[Zookeeper 2]
        Z3[Zookeeper 3]
    end

    subgraph Kafka Cluster
        B1[Broker 1]
        B2[Broker 2]
        B3[Broker 3]
    end

    subgraph Monitoring
        P[Prometheus]
        G[Grafana]
        A[Alertmanager]
    end

    Producers --> B1
    Producers --> B2
    Producers --> B3

    B1 --> Consumers
    B2 --> Consumers
    B3 --> Consumers

    B1 --> Z1
    B2 --> Z2
    B3 --> Z3

    B1 --> P
    B2 --> P
    B3 --> P

    P --> G
    P --> A
```

---

### 🖼️ Diagramme (Image fallback)

![Kafka Architecture](https://raw.githubusercontent.com/confluentinc/confluentinc.github.io/master/assets/images/blog/kafka-architecture.png)

---

## 🎯 Objectifs

Ces labs ont pour but de te permettre de :

- Comprendre l’architecture de Kafka (brokers, partitions, replication…)
- Installer et configurer un cluster Kafka
- Administrer les topics, producers et consumers
- Mettre en place du monitoring (Prometheus, Grafana…)
- Gérer les opérations courantes (rebalance, scaling, troubleshooting)
- Appliquer les bonnes pratiques d’exploitation

---

## 📦 Contenu

👉 Fichier principal :

`Kafka-labs-admin.md`

### 🔹 Labs inclus :

#### 1. Setup

* Installation Java & Kafka
* Configuration Linux

#### 2. Cluster Kafka

* Setup multi-brokers
* Configuration ZooKeeper

#### 3. Operations

* Création de topics
* Production / consommation

#### 4. Administration avancée

* Consumer Groups
* Rebalancing
* Replication

#### 5. Monitoring

* JMX Exporter
* Prometheus
* Grafana dashboards
* Alertmanager

#### 6. Scénarios réels

* Simulation de panne
* Scaling
* Troubleshooting

---

## ⚙️ Prérequis

* Linux / MacOS
* Java (JDK 8+)
* Docker (recommandé)

Connaissances utiles :

* Linux
* Réseau
* Concepts Kafka

---

## 🚀 Quick Start

```bash
git clone https://github.com/hisi91/KAFKA-LABS.git
cd KAFKA-LABS
cat Kafka-labs-admin.md
```

---

## 📊 Monitoring Stack

| Tool         | Rôle                       |
| ------------ | -------------------------- |
| Prometheus   | Collecte des métriques     |
| Grafana      | Visualisation              |
| Alertmanager | Alerting                   |
| JMX Exporter | Exposition métriques Kafka |

---

## 🧪 Cas d’usage

* Haute disponibilité Kafka
* Réplication des partitions
* Debugging cluster
* Monitoring production
* Optimisation performance

---

## 🤝 Contribution

Les contributions sont les bienvenues :

* Nouveaux labs
* Dashboards Grafana
* Scripts d’automatisation
* Fix & amélioration

```bash
# Workflow
Fork → Branch → Commit → Pull Request
```

# 📊 Kafka Confluent Labs - Administration

## coming soon ...


---

## ⭐ Support

Si ce repo t’aide :

👉 Mets une ⭐ sur GitHub
👉 Partage avec d’autres devs

---

## 👨‍💻 Auteur

**Yassine SIHI**
