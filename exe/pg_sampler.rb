#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/pg_sampler'

sampler = PGSampler.new
Signal.trap('SIGTERM') do
  puts 'SIGTERM received, signaling runner to stop.'
  sampler.stop
end
sampler.run
puts 'Sampler stopped.'
