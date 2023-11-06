#!/usr/bin/env ruby
# frozen_string_literal: true

require 'influxdb-client'

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

    write_api = @client.create_write_api

    (1..5).each do |i|
      data = "point,table=my-table result=#{i + (rand * 10).to_i}"
      write_api.write(data:, bucket: 'ruby_test', org: 'inventium')

      puts "write point #{i}"
    end

    # Example data - replace with actual counts from your pg_locks query
    lock_data = [
      { mode: 'AccessExclusiveLock', count: 5 },
      { mode: 'RowShareLock', count: 3 }
      # ... add more modes as needed
    ]

    # Construct the payload
    influx_payload = lock_data.map do |lock|
      "lock_modes,host=my_host,db=my_db mode=\"#{lock[:mode]}\",lock_count=#{lock[:count]}"
    end.join("\n")
    puts influx_payload

    write_api.write(data: influx_payload, bucket: 'ruby_test', org: 'inventium')
  end

  def write_point(measurement, tags, fields, timestamp = nil)
    data = {
      values: fields,
      tags:
    }
    data[:time] = timestamp if timestamp

    @client.write_point(measurement, data)
  end
end

# Example usage:

# client = InfluxDBClient.new(host: 'localhost', port: 8086, user: 'doolin', password: 'influxdb', bucket: 'ruby_test')
InfluxDBClient.new(host: 'localhost', port: 8086, user: 'doolin', password: 'influxdb', bucket: 'ruby_test')

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
