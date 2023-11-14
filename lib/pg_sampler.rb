#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pg'
require 'net/http'
require 'uri'
require_relative 'influx_db_client'

# Minimal example of sampling PostgreSQL locks and writing to InfluxDB.
class PGSampler
  # TODO: clean up attr_readers, not all of them are needed.
  attr_reader :pg_options, :influxdb_host, :influxdb_port, :influxdb_org, :influxdb_bucket

  PG_OPTIONS = {
    host: 'localhost',
    dbname: 'publisher',
    user: 'postgres',
    password: 'foobar',
    port: '5435'
  }.freeze

  def initialize
    @pg_options = PG_OPTIONS

    # TODO: remove as many of these as possible.
    @influxdb_host = 'localhost'
    @influxdb_port = 8086
    @influxdb_org = 'inventium'
    @influxdb_bucket = 'pg_test'
    @influx_client = InfluxDBClient.new(host: 'localhost', port: 8086, bucket: 'ruby_test', org: 'inventium')
  end

  def influx_query
    'locks,mode=%<lock_modes>s lock_count=%<lock_counts>s %<current_time>s'
  end

  def run
    PG::Connection.open(pg_options) do |conn|
      current_time = Time.now.to_f * 1_000_000_000
      get_pg_locks(conn).each do |lock|
        payload = format(influx_query, lock_modes: lock['mode'], lock_counts: lock['lock_count'],
                                       current_time: current_time.to_i)
        @influx_client.insert(payload)
      end
    end
  rescue PG::Error => e
    puts "Unable to connect to PostgreSQL: #{e.message}"
  end

  private

  def query
    <<-SQL
      SELECT
        pg_locks.mode,
        count(*) AS lock_count
      FROM
        pg_locks
      JOIN
        pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid
      WHERE
        pg_stat_activity.datname = current_database()
      GROUP BY
        pg_locks.mode;
    SQL
  end

  def get_pg_locks(conn)
    conn.exec_params(query)
  rescue PG::Error => e
    puts "Failed to retrieve PostgreSQL locks: #{e.message}"
    []
  end
end
