#!/usr/bin/env ruby
# frozen_string_literal: true

require 'influxdb-client'
require 'time'

# TODO: dig into how influx structures and stores data.
# TODO: dig into how influx queries data.
# TODO: dig into how influx visualises data.
# TODO: dig into how influx alerts on data.
# TODO: dig into how influx manages data.
#
# Minimal example of writing to InfluxDB using the influxdb-client gem.
class InfluxDBClient
  # def initialize(host:, port:, user:, password:, bucket:)
  def initialize(*)
    token = ENV['INFLUX_LOCAL_TOKEN']
    @client = InfluxDB2::Client.new('http://localhost:8086',
                                    token,
                                    bucket: 'ruby_test',
                                    org: 'inventium',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false)
  end

  # https://docs.influxdata.com/influxdb/v2/get-started/write/

  def write
    lock_modes = %w[AccessExclusiveLock RowShareLock]
    lock_counts = (4..123).to_a
    current_time = Time.now.to_i * 1_000_000_000

    2.times do
      payload = \
        "locks,host=my_host,db=testem mode=\"#{lock_modes.sample}\",lock_count=#{lock_counts.sample} #{current_time}"
      write_api.write(data: payload, bucket: 'ruby_test', org: 'inventium')

      puts payload
      sleep 0.1
    end
  end

  def write_demo1
    write_api = @client.create_write_api

    (1..5).each do |i|
      data = "point,table=my-table result=#{i + (rand * 10).to_i}"
      write_api.write(data:, bucket: 'ruby_test', org: 'inventium')

      puts "write point #{i}"
    end
  end

  def write_demo2
    write_api = @client.create_write_api
    # Example data - replace with actual counts from your pg_locks query
    lock_data = [
      { mode: 'AccessExclusiveLock', count: 5 },
      { mode: 'RowShareLock', count: 3 }
      # ... add more modes as needed
    ]

    # Construct the payload
    # TODO: how big can the payload be?
    influx_payload = lock_data.map do |lock|
      "lock_modes,host=my_host,db=testem mode=\"#{lock[:mode]}\",lock_count=#{lock[:count]}"
    end.join("\n")
    puts influx_payload

    write_api.write(data: influx_payload, bucket: 'ruby_test', org: 'inventium')
  end

  # Use the official documentation example
  # https://docs.influxdata.com/influxdb/v2/get-started/write/
  #
  # measurement,tag_key1=tag_val1,tag_key2=tag_val2 field_key1="field_val1",field_key2=field_val2 timestamp
  #
  def write_demo3
    lock_modes = %w[AccessExclusiveLock RowShareLock]
    lock_counts = (4..123).to_a

    100.times do
      # TODO: ensure milliseconds are acquired.
      current_time = Time.now.to_i * 1_000_000_000
      # Change to do 100 of each lock mode.
      payload = \
        "locks,mode=#{lock_modes.sample} lock_count=#{lock_counts.sample} #{current_time}"
      write_api.write(data: payload, bucket: 'ruby_test', org: 'inventium')

      puts payload
      sleep 2 # change to 0.1 once milliconds are acquired.
    end

    # write_api.write(data: influx_payload, bucket: 'ruby_test', org: 'inventium')
  end

  def write_point(measurement, tags, fields, timestamp = nil)
    data = {
      values: fields,
      tags:
    }
    data[:time] = timestamp if timestamp

    @client.write_point(measurement, data)
  end

  def write_api
    @client.create_write_api
  end
end

# Example usage:

# client = InfluxDBClient.new(host: 'localhost', port: 8086, user: 'doolin', password: 'influxdb', bucket: 'ruby_test')
client = InfluxDBClient.new(host: 'localhost', port: 8086, user: 'doolin', password: 'influxdb', bucket: 'ruby_test')
# client.write_demo1
# client.write_demo2
client.write_demo3
# client.write

# client.write_point('my_measurement', { tag1: 'value1', tag2: 'value2' }, { field1: 123, field2: 'abc' })

# __END__

# SELECT
#   pg_stat_activity.pid,
#   pg_stat_activity.query,
#   pg_locks.locktype,
#   pg_locks.relation::regclass,
#   pg_locks.mode,
#   pg_locks.granted
# FROM
#   pg_locks
# JOIN
#   pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid
# WHERE
#   pg_stat_activity.datname = current_database();

# SELECT
#   pg_stat_activity.pid,
#   left(pg_stat_activity.query, 20) AS truncated_query,
#   pg_locks.locktype,
#   pg_locks.relation::regclass,
#   pg_locks.mode,
#   pg_locks.granted
# FROM
#   pg_locks
# JOIN
#   pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid
# WHERE
#   pg_stat_activity.datname = current_database();

# # https://www.postgresql.org/docs/16/view-pg-locks.html
# SELECT
#   pg_locks.mode,
#   count(*) AS lock_count
# FROM
#   pg_locks
# JOIN
#   pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid
# WHERE
#   pg_stat_activity.datname = current_database()
# GROUP BY
#   pg_locks.mode;
