# Monitoring

## Ceilometer

- data type
  - measurements
    - output
      - Monasca
      - gnocchi
  - alarms
    - MySQL
    - PostgreSQL
  - events
    - output:
      - ElasticSearch
      - MongoDB
      - MySQL
      - PostgreSQL

## Monasca

- api accept
  - ceilometer inputs
  - log inputs
- store data to storage
  - ES
- visualization
  - grafana

## log agent

    - logstash to Monasca API
    - fluentd to Monasca API

## Prometheus

- server: prometheus
- exporter
  - [openstack-exporter](https://github.com/openstack-exporter/openstack-exporter)
- visualization
  - grafana
- alerting: Alert Manager
