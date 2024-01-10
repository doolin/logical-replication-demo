#!/usr/bin/env ruby
# frozen_string_literal: true

# https://github.com/influxdata/influxdb-client-ruby
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
  attr_reader :host, :port, :bucket, :org, :token

  # TODO: change to options hash.
  def initialize(options = {})
    @host = options[:host]
    @port = options[:port]
    @bucket = options[:bucket]
    @org = options[:org]
    @token = ENV.fetch('INFLUX_LOCAL_TOKEN', nil)
  end

  def client
    @client ||= InfluxDB2::Client.new(
      'http://localhost:8086',
      token,
      bucket:,
      org:,
      precision: InfluxDB2::WritePrecision::NANOSECOND,
      use_ssl: false
    )
  end

  def payload
    lock_modes = %w[AccessExclusiveLock RowShareLock]
    lock_counts = (4..123).to_a
    # TODO: ensure milliseconds are acquired.
    current_time = Time.now.to_i * 1_000_000_000

    # TODO: factor this string into a method.
    "locks,mode=#{lock_modes.sample} lock_count=#{lock_counts.sample} #{current_time}"
  end

  # Use the official documentation example
  # https://docs.influxdata.com/influxdb/v2/get-started/write/
  #
  # measurement,tag_key1=tag_val1,tag_key2=tag_val2 field_key1="field_val1",field_key2=field_val2 timestamp
  #
  def insert_demo(count)
    count.times do
      insert(payload)
      sleep 1.1 # change to 0.1 once milliconds are acquired.
    end
  end

  def insert(payload)
    write_api.write(data: payload)
    puts payload
  end

  def write_api
    @write_api ||= client.create_write_api
  end
end

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
