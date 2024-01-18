#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/books_inserter'

# Daemon execution
inserter = BooksInserter.new
begin
  inserter.run
ensure
  inserter.close_db_connection
end

# Main execution
threads = []
5.times do |i|
  threads << Thread.new do
    inserter = BooksInserter.new
    begin
      inserter.run
    rescue StandardError => error
      puts "Thread #{i} encountered an error: #{error.message}"
    ensure
      inserter.close_db_connection
    end
  end
end

threads.each(&:join) # This will cause the main thread to wait for all inserter threads to complete

# TODO: Trap ^C for a clean exit.
