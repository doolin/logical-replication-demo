#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/pg_sampler'
require 'optparse'

options = {
  scale: 10,
  threads: 3,
  clients: 10,
  duration: 2,
  sleep_time: 0.25
}

OptionParser.new do |opts|
  opts.banner = 'Usage: pg_bench [options]'

  opts.on('-T', '--time DURATION', Integer, 'Duration of sampling run in seconds') do |duration|
    options[:duration] = duration
  end

  opts.on('-s', '--sleep_time SLEEP_TIME', Float, 'Sleep time between samples') do |sleep_time|
    options[:sleep_time] = sleep_time
  end
end.parse!

sampler = PGSampler.new(options)
Signal.trap('SIGTERM') do
  puts 'SIGTERM received, signaling runner to stop.'
  sampler.stop
end
sampler.run
puts 'Sampler stopped.'
