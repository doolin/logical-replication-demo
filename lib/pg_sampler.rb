#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pg'
require 'net/http'
require 'uri'
require_relative 'influx_db_client'

# Minimal example of sampling PostgreSQL locks and writing to InfluxDB.
class PGSampler
  attr_reader :pg_options, :influxdb_host, :influxdb_port, :influxdb_org, :influxdb_bucket, :influxdb_token

  # TODO: factor out the options into a method.
  def initialize # rubocop:disable Metrics/MethodLength
    @pg_options = {
      host: 'localhost',
      dbname: 'publisher',
      user: 'postgres',
      password: 'foobar',
      port: '5435'
    }

    @influxdb_host = 'localhost'
    @influxdb_port = 8086
    @influxdb_org = 'inventium'
    @influxdb_bucket = 'pg_test'
    @influxdb_token = ENV.fetch('INFLUX_LOCAL_TOKEN', nil)
    @influx_client = InfluxDBClient.new(host: 'localhost', port: 8086, bucket: 'ruby_test', org: 'inventium')
  end

  def run
    PG::Connection.open(pg_options) do |conn|
      # Get lock data
      locks_data = get_pg_locks(conn)
      puts "Locks data: #{locks_data}"

      # Write to InfluxDB
      write_to_influx(locks_data) unless locks_data.empty?

      # Demo writing to InfluxDB just to make sure it works.
      lock_modes = %w[AccessExclusiveLock RowShareLock]
      lock_counts = (4..123).to_a
      # TODO: ensure milliseconds are acquired.
      current_time = Time.now.to_i * 1_000_000_000

      # TODO: factor this string into a method.
      payload = "locks,mode=#{lock_modes.sample} lock_count=#{lock_counts.sample} #{current_time}"

      @influx_client.insert(payload)
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

  # TODO: factor out the query into a method.
  # TODO: for an initial proof of concept, return dummy locks data.
  def get_pg_locks(conn)
    puts pg_options
    results = conn.exec_params(query) # , [pg_options[:host], pg_options[:dbname]])

    puts "Results: #{results}"

    # 3.2.2 :001 > results
    #  => #<PG::Result:0x000000010445fce0 status=PGRES_TUPLES_OK ntuples=2 nfields=2 cmd_tuples=2>
    #  3.2.2 :002 > results[0]
    #   => {"mode"=>"AccessShareLock", "lock_count"=>"8"}
    #  3.2.2 :003 > results[1]
    #   => {"mode"=>"ExclusiveLock", "lock_count"=>"1"}

    # puts query
    conn.exec_params(query, [pg_options[:host], pg_options[:dbname]]).map do |row|
      row['locks']
    end
  rescue PG::Error => e
    puts "Failed to retrieve PostgreSQL locks: #{e.message}"
    []
  end

  def write_to_influx(data)
    uri = URI.parse("http://#{influxdb_host}:#{influxdb_port}/api/v2/write?org=#{influxdb_org}&bucket=#{influxdb_bucket}&precision=s")
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'text/plain; charset=utf-8'
    request['Authorization'] = "Token #{influxdb_token}"
    request.body = data.join("\n")

    req_options = { use_ssl: uri.scheme == 'https' }

    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  rescue StandardError => e
    puts "Failed to write to InfluxDB: #{e.message}"
  end
end

# sampler = PGSampler.new
# sampler.run
