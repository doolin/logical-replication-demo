#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pg'
require 'faker'

# Insert books into the database at random intervals controlled
# by the mean value of a Rayleigh distribution. This gives us a
# high rate near the mean, but also a long tail of low rates.
class BooksInserter
  def initialize
    @connection_params = {
      host: 'localhost',
      port: '5435',
      dbname: 'publisher',
      user: 'postgres',
      password: 'foobar'
    }
    @topics = %w[technical leadership]
    connect_to_db
  end

  def connect_to_db
    @conn = PG.connect(@connection_params)
  rescue PG::Error => error
    puts "Unable to connect to database: #{error.message}"
    exit 1
  end

  def close_db_connection
    @conn&.close
  end

  def insert_book
    title = Faker::Book.title
    topic = @topics.sample
    sku = rand(1..10_000)

    @conn.exec_params(
      'INSERT INTO books (sku, title, topic) VALUES ($1, $2, $3)',
      [sku, title, topic]
    )
  rescue PG::Error => error
    puts "Insert failed: #{error.message}"
  end

  # Run the inserter indefinitely until killed.
  def run
    loop do
      insert_book
      sleep_random_time
    end
  end

  # Sleeps for a random amount of time using a Rayleigh distribution
  def sleep_random_time
    sigma = 0.001 / Math.sqrt(Math::PI / 2) # Scale parameter sigma for mean 0.001
    sleep(rand_rayleigh(sigma))
  end

  # Generate a random number using the Rayleigh distribution
  def rand_rayleigh(sigma)
    u = rand(0.0..1.0)
    (sigma * Math.sqrt(-2 * Math.log(1 - u)))
  end
end
