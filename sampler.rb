#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pg'
require 'net/http'
require 'uri'

# This script is not working. It is supposed to query PostgreSQL for locks and write the data to InfluxDB.

# PostgreSQL credentials
pg_options = {
  host: 'localhost',
  dbname: 'publisher',
  user: 'postgres',
  password: 'foobar',
  port: '5435'
}

# InfluxDB credentials
influxdb_host = 'localhost'
influxdb_port = 8086
influxdb_org = 'inventium'
influxdb_bucket = 'pg_test'
influxdb_token = ENV.fetch('INFLUX__LOCAL_TOKEN', nil)

# Function to query PostgreSQL and return locks
def get_pg_locks(conn, pg_options)
  query = <<-SQL
    SELECT
      -- 'locks,host=' || $1 || ',database=' || $2 || ' user=' || pid || ',value=' || count(*)
      'locks,host=' || $1 || ',database=' || $2 || ' user=' || ',value=' || count(*)
    FROM pg_locks l
    JOIN pg_stat_activity a ON l.pid = a.pid
    WHERE NOT granted
    GROUP BY a.pid;
  SQL

  puts

  # Execute the query
  conn.exec_params(query, [pg_options[:host], pg_options[:dbname]]).map do |row|
    puts 'here'
    row['locks']
    puts row
  end
end

# Function to write data to InfluxDB
def write_to_influx(data, influxdb_host, influxdb_port, influxdb_org, influxdb_bucket, influxdb_token)
  uri = URI.parse("http://#{influxdb_host}:#{influxdb_port}/api/v2/write?org=#{influxdb_org}&bucket=#{influxdb_bucket}&precision=s")
  request = Net::HTTP::Post.new(uri)
  request.content_type = 'text/plain; charset=utf-8'
  request['Authorization'] = "Token #{influxdb_token}"
  request.body = data.join("\n")

  req_options = {
    use_ssl: uri.scheme == 'https'
  }

  Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end
end

# Connect to PostgreSQL
PG::Connection.open(pg_options) do |conn|
  # Get lock data
  locks_data = get_pg_locks(conn, pg_options)
  puts "Locks data: #{locks_data}"

  # Write to InfluxDB
  unless locks_data.empty?
    write_to_influx(locks_data, influxdb_host, influxdb_port, influxdb_org, influxdb_bucket,
                    influxdb_token)
  end
end
