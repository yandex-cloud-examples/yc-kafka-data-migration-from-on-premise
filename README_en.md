# Migrating a database from a third-party Apache Kafka® cluster to a Yandex Managed Service for Apache Kafka® cluster

You can migrate topics from an Apache Kafka® source cluster to a [Managed Service for Apache Kafka®](https://yandex.cloud/docs/managed-kafka) target cluster in two ways:

* Using the MirrorMaker connector built in Managed Service for Apache Kafka®.
* Using MirrorMaker 2.0.

See [this tutorial](https://yandex.cloud/docs/tutorials/dataplatform/kafka-connector) to learn how to prepare the infrastructure for your VM and Managed Service for Apache Kafka® using Terraform. This repository contains the configuration files you will need: [kafka-mirrormaker-connector.tf](kafka-mirrormaker-connector.tf) and [kafka-mirror-maker.tf](kafka-mirror-maker.tf).
