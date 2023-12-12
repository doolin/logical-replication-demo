apiVersion: 1

datasources:
- name: InfluxDB
  type: influxdb
  access: proxy
  url: http://pubmetrics:8086
  jsonData:
    httpMode: POST
    organization: inventium
    defaultBucket: ruby_test
    version: "Flux" # 2  # This is for InfluxDB 2.x with Flux
  secureJsonData:
    token: INFLUXDB_TOKEN
