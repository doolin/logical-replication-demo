#!/usr/bin/env ruby
# frozen_string_literal: true

# log stream --predicate '(process == "iTerm2")'
require 'open3'
# require 'clickhouse'
require 'faraday'
# require 'faraday/middleware'
require 'debug'
require 'base64'
require 'time'

# Encode the credentials
# username = 'username' # Replace with your ClickHouse username
# password = 'password' # Replace with your ClickHouse password
# encoded_credentials = Base64.strict_encode64("#{username}:#{password}")

conn = Faraday.new(url: 'http://localhost:8123/') do |f|
  f.adapter Faraday.default_adapter
end

def encoded_credentials
  username = 'username' # Replace with your ClickHouse username
  password = 'password' # Replace with your ClickHouse password
  Base64.strict_encode64("#{username}:#{password}")
end

create_table_query = <<-SQL
  CREATE TABLE IF NOT EXISTS my_database.logs (
    timestamp DateTime,
    message String
  ) ENGINE = MergeTree()
  ORDER BY timestamp
SQL

begin
  puts 'Creating table...'
  response = conn.post do |req|
    req.url "/?query=#{URI.encode_www_form_component(create_table_query)}"
    req.headers['Authorization'] = "Basic #{encoded_credentials}"
  end
  puts response.body
rescue Faraday::ConnectionFailed => error
  puts error
end

# command = "log stream --predicate '(process == \"iTerm2\")' --info"
command = "log show --predicate '(process == \"iTerm2\")' --info --style syslog"

# Use Open3.popen3 to execute the command and capture stdout, stderr, and the status
Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
  logs = stdout.readlines
  # logs = logs.last(10) # Get the latest 10 log entries

  logs.each do |line|
    # Extract timestamp and message from the log line
    timestamp_str, message = line.split(' ', 2)
    puts timestamp_str
    begin
      timestamp = Time.parse(timestamp_str).strftime('%Y-%m-%d %H:%M:%S')

      # Insert the log into ClickHouse
      insert_query = <<-SQL
        INSERT INTO my_database.logs (timestamp, message) VALUES ('#{timestamp}', '#{message.strip}')
      SQL

      conn.post do |req|
        req.url "/?query=#{URI.encode_www_form_component(insert_query)}"
        req.headers['Authorization'] = "Basic #{encoded_credentials}"
      end
    rescue ArgumentError
      warn "Failed to parse timestamp: #{timestamp_str}"
    end
  end

  # Check the exit status
  exit_status = wait_thr.value
  unless exit_status.success?
    warn "Command failed with status (#{exit_status.exitstatus}):"
    stderr.each_line do |line|
      warn line
    end
  end
end
