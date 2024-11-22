# Infrastructure for the Yandex Cloud Managed Service for Apache Kafka® cluster and Virtual Machine
#
# RU: https://yandex.cloud/ru/docs/managed-kafka/tutorials/kafka-connectors
# EN: https://yandex.cloud/en/docs/managed-kafka/tutorials/kafka-connectors
#
# Configure the parameters of the Managed Service for Apache Kafka® cluster and Virtual Machine:

locals {
  kf_password     = "" # Apache Kafka® admin's password
  kf_version      = "" # Desired version of Apache Kafka®. For available versions, see the documentation main page: https://yandex.cloud/en/docs/managed-kafka/.
  image_id        = "" # Public image ID from https://yandex.cloud/en/docs/compute/operations/images-with-pre-installed-software/get-list
  vm_username     = "" # Username to connect to the routing VM via SSH. Images with Ubuntu Linux use the `ubuntu` username by default.
  vm_ssh_key_path = "" # Path to the SSH public key for the routing VM. Example: "~/.ssh/key.pub".

  # The following settings are predefined. Change them only if necessary.
  network_name          = "network"       # Name of the network
  subnet_name           = "subnet-a"      # Name of the subnet
  zone_a_v4_cidr_blocks = "10.1.0.0/16"   # CIDR block for subnet in the ru-central1-a availability zone
  kf_cluster_name       = "kafka-cluster" # Name of the Apache Kafka® cluster
  kf_username           = "admin-cloud"   # Username of the Apache Kafka® cluster
}

# Network infrastructure

resource "yandex_vpc_network" "network" {
  description = "Network for the Managed Service for Apache Kafka® cluster and VM"
  name        = local.network_name
}

resource "yandex_vpc_subnet" "subnet-a" {
  description    = "Subnet in the ru-central1-a availability zone"
  name           = local.subnet_name
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [local.zone_a_v4_cidr_blocks]
}

resource "yandex_vpc_default_security_group" "security-group" {
  description = "Security group for the Managed Service for Apache Kafka® cluster and VM"
  network_id  = yandex_vpc_network.network.id

  ingress {
    description    = "Allow connections to the Managed Service for Apache Kafka® cluster from the Internet"
    protocol       = "TCP"
    from_port      = 9091
    to_port        = 9092
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow SSH connections for VM from the Internet"
    protocol       = "TCP"
    port           = 22
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
  description        = "Yandex Managed Service for Apache Kafka® cluster"
  name               = local.kf_cluster_name
  environment        = "PRODUCTION"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_default_security_group.security-group.id]

  config {
    brokers_count = 1
    version       = local.kf_version
    zones         = ["ru-central1-a"]
    kafka {
      resources {
        disk_size          = 10 # GB
        disk_type_id       = "network-hdd"
        resource_preset_id = "s2.micro"
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

# User of the Managed service for the Apache Kafka® cluster
resource "yandex_mdb_kafka_user" "mkf-user" {
  cluster_id = yandex_mdb_kafka_cluster.kafka-cluster.id
  name       = local.kf_username
  password   = local.kf_password
  permission {
    topic_name = "*"
    role       = "ACCESS_ROLE_ADMIN"
  }
}

# VM infrastructure

resource "yandex_compute_instance" "vm-mirror-maker" {
  description = "VM in Yandex Compute Cloud"
  name        = "vm-mirror-maker"
  platform_id = "standard-v3" # Intel Ice Lake

  resources {
    cores  = 2
    memory = 2 # GB
  }

  boot_disk {
    initialize_params {
      image_id = local.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a.id
    nat       = true # Required for connection from the Internet
  }

  metadata = {
    ssh-keys = "${local.vm_username}:${file(local.vm_ssh_key_path)}"
  }
}
