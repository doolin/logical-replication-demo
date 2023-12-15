#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/pg_bench'
require 'optparse'

options = {
  scale: 10,   # Default scale
  threads: 3,  # Default threads
  clients: 10, # Default clients
  duration: 5  # Default duration
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
