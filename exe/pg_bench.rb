#!/usr/bin/env ruby

require_relative '../lib/pg_bench'
require 'optparse'

# Configuration hash
options = {}

# Define the options and parse them
OptionParser.new do |opts|
  opts.banner = "Usage: pg_bench [options]"

  opts.on("-T", "--time DURATION", Integer, "Duration of benchmark run in seconds") do |duration|
    options[:duration] = duration
  end

  # You can add more options here as needed

end.parse!

PGBench.new(options).run_default

