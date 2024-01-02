#!/usr/bin/env ruby
# frozen_string_literal: true

# The pg_bench executable is a wrapper for the PGBench driver class.
# It is responsible for parsing command line options and passing them
# to the driver class. It also initializes the benchmark before running
# it.
#
# Run thie in the backbround with: nohup ./exe/pg_bench.rb > /dev/null 2>&1 &

require_relative '../lib/pg_bench'
require 'optparse'

# Default values. These can be overridden by command line options.
options = {
  scale: 10,
  threads: 3,
  clients: 10,
  duration: 5
}

# Define the options and parse them
OptionParser.new do |opts|
  opts.banner = 'Usage: pg_bench [options]'

  opts.on('-T', '--time DURATION', Integer, 'Duration of benchmark run in seconds') do |duration|
    options[:duration] = duration
  end

  opts.on('-s', '--scale SCALE', Integer, 'Scale factor for benchmark') do |scale|
    options[:scale] = scale
  end

  opts.on('-j', '--threads THREADS', Integer, 'Number of threads for benchmark') do |threads|
    options[:threads] = threads
  end

  opts.on('-c', '--clients CLIENTS', Integer, 'Number of clients for benchmark') do |clients|
    options[:clients] = clients
  end
end.parse!

puts "Configured options: #{options.inspect}"
PGBench.new(options).run
