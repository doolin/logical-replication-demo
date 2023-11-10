#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/influx_db_client'

client = InfluxDBClient.new(host: 'localhost', port: 8086, bucket: 'ruby_test', org: 'inventium')
client.insert_demo
