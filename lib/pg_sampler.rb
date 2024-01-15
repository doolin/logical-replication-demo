#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pg'
require 'net/http'
require 'uri'
require_relative 'pg_options'
require_relative 'influx_db_client'

# Minimal example of sampling PostgreSQL locks and writing to InfluxDB.
#
# Invoke ./exe/pg_sampler.rb to run it. It will write the influx query to
# stdout and continnuously scroll in the terminal. Could be redirected to
# /dev/null if desired. Could also be run in the background; the default
# duration of 300 seconds will ensure the script exits.
class PGSampler
  SLEEP_TIME = 0.25
  DURATION = 300
  INFLUXDB_OPTIONS = {
    host: 'localhost',
    port: 8086,
    bucket: 'ruby_test',
    org: 'inventium'
  }.freeze

  attr_reader :pg_options, :options

  def initialize(options)
    @options = options
    @pg_options = PG_OPTIONS
    @terminate = false
    @influx_client = InfluxDBClient.new(INFLUXDB_OPTIONS)
  end

  def influx_query
    'locks,mode=%<lock_modes>s lock_count=%<lock_counts>s %<current_time>s'
  end

  def locks(conn)
    current_time = (Time.now.to_f * 1_000_000_000).to_i

    get_pg_locks(conn).each do |lock|
      payload = format(influx_query, lock_modes: lock['mode'], lock_counts: lock['lock_count'],
                                     current_time:)
      @influx_client.insert(payload)
    end
  end

  def size(conn)
    current_time = (Time.now.to_f * 1_000_000_000).to_i
    influx_query = 'size,database=publisher size=%<size>s %<current_time>s'

    get_pg_size(conn).each do |size|
      payload = format(influx_query, size: size['pg_database_size'], current_time:)
      @influx_client.insert(payload)
    end
  end

  def mean_time(conn)
    current_time = (Time.now.to_f * 1_000_000_000).to_i
    influx_query = 'mean_time_query,database=publisher mean_time=%<mean_time>s %<current_time>s'

    get_pg_mean_query(conn).each do |mean|
      payload = format(influx_query, mean_time: mean['avg_exec_time'], current_time:)
      @influx_client.insert(payload)
    end
  end

  def current_time
    (Time.now.to_f * 1_000_000_000).to_i
  end

  def connection_counts(conn)
    influx_query = 'connection_counts,database=publisher connection_counts=%<connection_counts>s %<current_time>s'

    get_pg_connections(conn).each do |connection|
      payload = format(influx_query, connection_counts: connection['count'], current_time:)
      @influx_client.insert(payload)
    end
  end

  def transaction_rates(conn)
    influx_query = 'transaction_rates,database=publisher transaction_rates=%<transaction_rates>s %<current_time>s'

    get_pg(conn, transaction_rates_query).each do |rates|
      payload = format(influx_query, transaction_rates: rates['count'], current_time:)
      @influx_client.insert(payload)
    end
  end

  def cache_hit_ratio(conn)
    influx_query = 'cache_hit_ratio,database=publisher cache_hit_ratio=%<cache_hit_ratio>s %<current_time>s'

    get_pg(conn, cache_hit_query).each do |ratio|
      payload = format(influx_query, cache_hit_ratio: ratio['ratio'], current_time:)
      @influx_client.insert(payload)
    end
  end

  def checkpoints(conn)
    influx_query = 'checkpoints,database=publisher checkpoints_timed=%<checkpoints_timed>s,checkpoints_requested=%<checkpoints_requested>s %<current_time>s' # rubocop:disable Layout/LineLength Metrics/LineLength

    get_pg(conn, checkpoints_query).each do |checkpoints|
      payload = format(influx_query, checkpoints_timed: checkpoints['Timed Checkpoints'], checkpoints_requested: checkpoints['Requested Checkpoints'], current_time:) # rubocop:disable Layout/LineLength Metrics/LineLength
      @influx_client.insert(payload)
    end
  end

  def replication_lag(conn)
    influx_query = 'replication_lag,database=publisher,application_name=%<application_name>s replay_lag_seconds=%<replay_lag_seconds>s,write_lag_seconds=%<write_lag_seconds>s %<current_time>s' # rubocop:disable Layout/LineLength Metrics/LineLength

    get_pg(conn, replication_lag_query).each do |replication_lag|
      payload = format(
        influx_query,
        application_name: replication_lag['application_name'],
        replay_lag_seconds: replication_lag['replay_lag_seconds'],
        write_lag_seconds: replication_lag['write_lag_seconds'],
        current_time:
      )
      @influx_client.insert(payload)
    end
  end

  def get_pg(conn, query)
    conn.exec_params(query)
  rescue PG::Error => e
    puts "Failed to retrieve PostgreSQL size: #{e.message}"
    []
  end

  # There are a couple of ways to loop this. One is to loop outside
  # the connection, which will open a new connection for each loop.
  # Another is to loop inside the connection, which will keep the
  # connection open for the duration of the loop. The latter is
  # preferable for performance reasons. The connection is closed
  # automatically when the block exits. Which to use depends on what
  # we want to test.
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def run
    stop_time = Time.now + duration
    PG::Connection.open(pg_options) do |conn|
      loop do
        break if @terminate
        break if Time.now > stop_time

        locks(conn)
        size(conn)
        mean_time(conn)
        connection_counts(conn)
        transaction_rates(conn)
        cache_hit_ratio(conn)
        checkpoints(conn)
        replication_lag(conn)
        sleep sleep_time
      end
    end
  rescue PG::Error => e
    puts "Unable to connect to PostgreSQL: #{e.message}"
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def stop
    @terminate = true
  end

  private

  def sleep_time
    options[:sleep_time] || SLEEP_TIME
  end

  def duration
    options[:duration] || DURATION
  end

  def connections_query
    'SELECT count(*) FROM pg_stat_activity'
  end

  def get_pg_connections(conn)
    conn.exec_params(connections_query)
  rescue PG::Error => e
    puts "Failed to retrieve PostgreSQL connections: #{e.message}"
    []
  end

  def locks_query
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
    conn.exec_params(locks_query)
  rescue PG::Error => e
    puts "Failed to retrieve PostgreSQL locks: #{e.message}"
    []
  end

  def transaction_rates_query
    <<~SQL
      SELECT count(*) FROM pg_stat_activity
      WHERE query = 'SELECT'
      OR query = 'INSERT'
      OR query = 'UPDATE'
      OR query = 'DELETE'
    SQL
  end

  def cache_hit_query
    <<-SQL
      SELECT sum(blks_hit) / nullif(sum(blks_read + blks_hit), 0) AS ratio FROM pg_stat_database
    SQL
  end

  def checkpoints_query
    <<~SQL
      SELECT checkpoints_timed AS "Timed Checkpoints",
        checkpoints_req AS "Requested Checkpoints"
      FROM pg_stat_bgwriter;
    SQL
  end

  # replay_lag and write_lag interval types in PostgreSQL.
  def replication_lag_query
    <<~SQL
      SELECT
        application_name,
        COALESCE(EXTRACT(EPOCH FROM replay_lag), 0) AS replay_lag_seconds,
        COALESCE(EXTRACT(EPOCH FROM write_lag), 0) AS write_lag_seconds
      FROM pg_stat_replication;
    SQL
  end

  def mean_time_query
    <<~SQL
      SELECT
        NOW() as time,
        (SUM(total_exec_time) / SUM(calls)) as avg_exec_time#{' '}
      FROM pg_stat_statements;
    SQL
  end

  def get_pg_mean_query(conn)
    conn.exec_params(mean_time_query)
  rescue PG::Error => e
    puts "Failed to retrieve PostgreSQL size: #{e.message}"
    []
  end

  def size_query
    "SELECT pg_database_size('publisher');"
  end

  def get_pg_size(conn)
    conn.exec_params(size_query)
  rescue PG::Error => e
    puts "Failed to retrieve PostgreSQL size: #{e.message}"
    []
  end
end
