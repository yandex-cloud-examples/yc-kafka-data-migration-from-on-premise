# Миграция базы данных из стороннего кластера Apache Kafka® в Yandex Managed Service for Apache Kafka®

Вы можете перенести топики из кластера-источника Apache Kafka® в кластер-приемник [Managed Service for Apache Kafka®](https://yandex.cloud/ru/docs/managed-kafka) двумя способами:

* С помощью встроенного в Managed Service for Apache Kafka® MirrorMaker-коннектора.
* С помощью утилиты MirrorMaker 2.0.

Подготовка инфраструктуры для виртуальной машины и Managed Service for Apache Kafka® через Terraform описана в [практическом руководстве](https://yandex.cloud/ru/docs/tutorials/dataplatform/kafka-connector), необходимые для настройки конфигурационные файлы [kafka-mirrormaker-connector.tf](kafka-mirrormaker-connector.tf) и [kafka-mirror-maker.tf](kafka-mirror-maker.tf) расположены в этом репозитории.
