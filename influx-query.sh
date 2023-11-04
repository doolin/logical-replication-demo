#!/bin/bash

curl -X POST "http://localhost:8086/api/v2/query?org=inventium" \
--header "Authorization: Token $INFLUX_LOCAL_TOKEN" \
--header "Content-Type: application/vnd.flux" \
--data 'from(bucket: "testem")
  |> range(start: -20h)
  |> filter(fn: (r) => r["_measurement"] == "temperature" and r["sensor"] == "sensor1")'
