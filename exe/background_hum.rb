#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/pg_bench'
require 'optparse'

# Run a "background" benchmark for 10 minutes.
# This is to chew up mamory and CPU so we can see
# how the sampler reacts when random loads are applied.
options = {
  scale: 10,
  threads: 3,
  clients: 10,
  duration: 600
}

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
