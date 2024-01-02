#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/pg_bench'

# Run a "background" benchmark for 10 minutes.
# This is to chew up mamory and CPU so we can see
# how the sampler reacts when random loads are applied.
options = {
  scale: 10,   # Default scale
  threads: 3,  # Default threads
  clients: 10, # Default clients
  duration: 600  # Default duration
}

puts "Configured options: #{options.inspect}"
PGBench.new(options).run
