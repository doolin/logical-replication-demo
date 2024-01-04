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
  DURATION = 60
  SCALE = 10
  CLIENTS = 10
  THREADS = 3

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
      end
    end
  end

  def run
    bench_sys(pgbench)
  end

  # Send an intermittent pulse of load to the database.
  def pulse
    @options[:duration] = 3
    @options[:scale] = 10
    stop_time = Time.now + 300
    while Time.now < stop_time
      bench_sys(pgbench)
      sleep 15
    end
  end

  def bench_sys(cmd)
    system(cmd)
  end

  def pgbench
    "PGPASSWORD=foobar pgbench -h #{HOST} -p #{PORT} -U #{PG_USER} -s #{scale} -T #{time_in_secongs} -c #{clients} -j #{threads} #{DB_NAME}"
  end

  def time_in_secongs
    options[:duration] || DURATION
  end

  def scale
    options[:scale] || SCALE
  end

  def clients
    options[:clients] || CLIENTS
  end

  def threads
    options[:threads] || THREADS
  end
end
