# frozen_string_literal: true

require_relative '../lib/books_inserter'
require 'faker'

RSpec.describe BooksInserter do
  subject(:inserter) { described_class.new }

  before do
    allow(inserter).to receive(:sleep_random_time) # Avoid actual sleeping
  end

  describe '#insert_book' do
    let(:title) { 'The Great Gatsby' }
    let(:topic) { 'technical' }
    let(:sku) { 1234 }

    before do
      allow(Faker::Book).to receive(:title).and_return(title)
      allow(inserter.instance_variable_get(:@topics)).to receive(:sample).and_return(topic)
      allow(inserter).to receive(:rand).with(1..10_000).and_return(sku)
    end

    it 'inserts a book into the database' do
      conn = inserter.instance_variable_get(:@conn)
      allow(conn).to receive(:exec_params) # Set up conn as a spy

      inserter.insert_book

      expect(conn).to have_received(:exec_params).with(
        'INSERT INTO books (sku, title, topic) VALUES ($1, $2, $3)',
        [sku, title, topic]
      )
    end
  end
end
