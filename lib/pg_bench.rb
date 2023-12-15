# frozen_string_literal: true

require 'pg'
require_relative 'pg_options'

# I think there are going to be two classes here, maybe three.
# One class will configure a pgbench command to pass to system.
# Another class will run the pgbench command, while checking for
# benchmark initialization before running the command.
# Will need a class to create and run experiments.

# Driver class for pgbench
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
  end

  def run
    bench_sys(pgbench)
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
