# Infrastructure for Yandex Cloud Managed Service for Apache Kafka® and MirrorMaker connector
#
# RU: https://yandex.cloud/ru/docs/managed-kafka/tutorials/kafka-connectors
# EN: https://yandex.cloud/en/docs/managed-kafka/tutorials/kafka-connectors
#
# Configure the parameters of the source and target clusters:

locals {
  source_user              = ""                          # Source cluster username
  source_password          = ""                          # Source cluster user's password
  source_alias             = "source"                    # Prefix for the source cluster
  source_bootstrap_servers = "<FQDN1>:9091,<FQDN2>:9091" # Bootstrap servers to connect to cluster
  target_password          = ""                          # Target cluster user's password
  target_alias             = "target"                    # Prefix for the target cluster
  topics_prefix            = "data.*"                    # Topics that must be migrated
  kafka_version            = ""                          # Desired version of Apache Kafka®. For available versions, see the documentation main page: https://yandex.cloud/en/docs/managed-kafka/.

  # The following settings are predefined. Change them only if necessary.
  network_name          = "network"       # Name of the network
  subnet_a_name         = "subnet-a"      # Name of the subnet in the ru-central1-a availability zone
  subnet_b_name         = "subnet-b"      # Name of the subnet in the ru-central1-b availability zone
  subnet_d_name         = "subnet-d"      # Name of the subnet in the ru-central1-d availability zone
  zone_a_v4_cidr_blocks = "10.1.0.0/16"   # CIDR block for subnet in the ru-central1-a availability zone
  zone_b_v4_cidr_blocks = "10.2.0.0/16"   # CIDR block for subnet in the ru-central1-b availability zone
  zone_d_v4_cidr_blocks = "10.3.0.0/16"   # CIDR block for subnet in the ru-central1-d availability zone
  target_cluster        = "kafka-cluster" # Name of the Apache Kafka® target cluster
  target_connector      = "replication"   # Name of the Apache Kafka® connector for the target cluster
  target_user           = "admin-cloud"   # Username of the Apache Kafka® for the target cluster
  sasl_mechanism        = "SCRAM-SHA-512" # Encryption algorythm for username and password
  security_protocol     = "SASL_SSL"      # Connection protocol for the MirrorMaker connector
}

# Network infrastructure

resource "yandex_vpc_network" "network" {
  description = "Network for the Managed Service for Apache Kafka® cluster and VM"
  name        = local.network_name
}

resource "yandex_vpc_subnet" "subnet-a" {
  description    = "Subnet in ru-central1-a availability zone"
  name           = local.subnet_a_name
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [local.zone_a_v4_cidr_blocks]
}

resource "yandex_vpc_subnet" "subnet-b" {
  description    = "Subnet in ru-central1-b availability zone"
  name           = local.subnet_b_name
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [local.zone_b_v4_cidr_blocks]
}

resource "yandex_vpc_subnet" "subnet-d" {
  description    = "Subnet in ru-central1-d availability zone"
  name           = local.subnet_d_name
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [local.zone_d_v4_cidr_blocks]
}

resource "yandex_vpc_default_security_group" "security-group" {
  description = "Security group for the Managed Service for Apache Kafka® cluster"
  network_id  = yandex_vpc_network.network.id

  ingress {
    description    = "Allow connections to the Managed Service for Apache Kafka® cluster from the Internet"
    protocol       = "TCP"
    from_port      = 9091
    to_port        = 9092
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow outgoing connections to any required resource"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Infrastructure for the Managed Service for Apache Kafka® cluster

resource "yandex_mdb_kafka_cluster" "kafka-cluster" {
  description        = "Managed Service for Apache Kafka® cluster"
  name               = local.target_cluster
  environment        = "PRODUCTION"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_default_security_group.security-group.id]

  config {
    brokers_count = 1
    version       = local.kafka_version
    zones         = ["ru-central1-a"]
    kafka {
      resources {
        disk_size          = 10 # GB
        disk_type_id       = "network-hdd"
        resource_preset_id = "s2.micro" # 2 vCPU, 8 GB RAM
      }
      kafka_config {
        auto_create_topics_enable = true
      }
    }
  }

  depends_on = [
    yandex_vpc_subnet.subnet-a
  ]
}

# User of the Managed Service for Apache Kafka® cluster
resource "yandex_mdb_kafka_user" "user" {
  cluster_id = yandex_mdb_kafka_cluster.kafka-cluster.id
  name       = local.target_user
  password   = local.target_password
  permission {
    topic_name = "*"
    role       = "ACCESS_ROLE_ADMIN"
  }
}

# MirrorMaker connector of the Managed Service for Apache Kafka® cluster
resource "yandex_mdb_kafka_connector" "connector" {
  cluster_id = yandex_mdb_kafka_cluster.kafka-cluster.id
  name       = local.target_connector
  tasks_max  = 3
  connector_config_mirrormaker {
    topics             = local.topics_prefix
    replication_factor = 1
    source_cluster {
      alias = local.source_alias
      external_cluster {
        bootstrap_servers = local.source_bootstrap_servers
        sasl_username     = local.source_user
        sasl_password     = local.source_password
        sasl_mechanism    = local.sasl_mechanism
        security_protocol = local.security_protocol
      }
    }
    target_cluster {
      alias = local.target_alias
      this_cluster {}
    }
  }
}
