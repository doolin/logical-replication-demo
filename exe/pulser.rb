#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/pg_bench'

# Run a "background" benchmark for 10 minutes.
# This is to chew up mamory and CPU so we can see
# how the sampler reacts when random loads are applied.
options = {
  scale: 10,
  threads: 3,
  clients: 10,
  duration: 600
}

puts "Configured options: #{options.inspect}"
PGBench.new(options).pulse
