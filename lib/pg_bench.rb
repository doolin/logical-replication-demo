# frozen_string_literal: true

require 'pg'
require_relative 'pg_options'

# Driver class for pgbench
#
# I think there are going to be two classes here, maybe three.
# One class will configure a pgbench command to pass to system.
# Another class will run the pgbench command, while checking for
# benchmark initialization before running the command.
# Will need a class to create and run experiments.
class PGBench
  attr_accessor :options

  DB_NAME = 'publisher'
  PG_USER = 'postgres'
  HOST = 'localhost'
  PORT = 5435
  DURATION = 120
  SCALE = 10
  CLIENTS = 10
  THREADS = 3
  SLEEP_TIME = 15
  FREQUENCY = 0.2

  def initialize(options = {})
    @options = options
    initialize_pg_bench
  end

  def initialize_pg_bench
    PG::Connection.open(PG_OPTIONS) do |conn|
      query = "SELECT 'table_exists' WHERE EXISTS (SELECT FROM pg_tables WHERE tablename = 'pgbench_accounts');"
      result = conn.exec(query)
      if result.ntuples.zero?
        puts 'Initializing pgbench'
        system("PGPASSWORD=foobar pgbench -i -h #{HOST} -p #{PORT} -U #{PG_USER} #{DB_NAME}")
        sleep 1
      end
    end
  end

  def run
    bench_sys(pgbench)
  end

  # Send an intermittent pulse of load to the database.
  def pulse
    stop_time = Time.now + time_in_seconds
    options[:duration] = 1.fdiv(options[:frequency] || FREQUENCY)

    while Time.now < stop_time
      bench_sys(pgbench)
      sleep sleep_time
    end
  end

  def custom
    stop_time = Time.now + time_in_seconds

    while Time.now < stop_time
      bench_sys(pgbench_custom)
      sleep sleep_time
    end
  end

  def bench_sys(cmd)
    # TODO: capture STDOUT and record in postgres
    system(cmd)
  end

  def pgbench
    <<~CMD
      PGPASSWORD=foobar pgbench \\
        -h #{HOST} \\
        -p #{PORT} \\
        -U #{PG_USER} \\
        -s #{scale} \\
        -T #{time_in_seconds} \\
        -c #{clients} \\
        -j #{threads} \\
        #{DB_NAME} --log
    CMD
  end

  def pgbench_custom
    <<~CMD
      PGPASSWORD=foobar pgbench \\
        -h #{HOST} \\
        -p #{PORT} \\
        -U #{PG_USER} \\
        -s #{scale} \\
        -T #{time_in_seconds} \\
        -c #{clients} \\
        -j #{threads} \\
        -f ./scripts/sql/pgbench_custom.sql \\
        #{DB_NAME} --log
    CMD
  end

  def time_in_seconds
    options[:duration] || DURATION
  end

  def scale
    options[:scale] || SCALE
  end

  def frequency
    options[:frequency] || FREQUENCY
  end

  def sleep_time
    options[:sleep_time] || SLEEP_TIME
  end

  def clients
    options[:clients] || CLIENTS
  end

  def threads
    options[:threads] || THREADS
  end
end
