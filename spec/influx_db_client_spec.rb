# frozen_string_literal: true

# require 'spec_helper'
require_relative '../lib/influx_db_client'

RSpec.describe InfluxDBClient do
  let(:host) { 'http://localhost' }
  let(:port) { '8086' }
  let(:bucket) { 'test_bucket' }
  let(:org) { 'test_org' }
  let(:token) { 'test_token' }

  before do
    allow(ENV).to receive(:fetch).with('INFLUX_LOCAL_TOKEN', nil).and_return(token)
  end

  describe 'initialization' do
    subject(:influx_client) { described_class.new(host:, port:, bucket:, org:) }

    it 'assigns host' do
      expect(influx_client.host).to eq(host)
    end

    it 'assigns port' do
      expect(influx_client.port).to eq(port)
    end

    it 'assigns bucket' do
      expect(influx_client.bucket).to eq(bucket)
    end

    it 'assigns org' do
      expect(influx_client.org).to eq(org)
    end

    it 'assigns token from ENV' do
      expect(influx_client.token).to eq(token)
    end
  end

  describe '#client' do
    subject(:client) { influx_client.client }

    let(:influx_client) { described_class.new(host:, port:, bucket:, org:) }

    it 'returns an InfluxDB2 client' do
      expect(client).to be_a(InfluxDB2::Client)
    end
  end

  describe '#payload' do
    subject(:payload) { described_class.new(host:, port:, bucket:, org:).payload }

    it 'generates a valid line protocol payload' do
      expect(payload).to match(/locks,mode=(AccessExclusiveLock|RowShareLock) lock_count=\d+ \d+/)
    end
  end

  describe '#insert_demo' do
    let(:client) { described_class.new(host:, port:, bucket:, org:) }
    let(:write_api_mock) { instance_spy(InfluxDB2::WriteApi) }

    before do
      allow(client).to receive(:write_api).and_return(write_api_mock)
      allow(client).to receive(:sleep) # Mocking sleep to prevent actual sleeping
    end

    it 'calls write on write_api with the correct data' do
      count = 2

      # Perform the action before setting the expectation
      silence_stream($stdout) { client.insert_demo(count) }

      # Use `have_received` to assert that `write` was called on the spy
      expect(write_api_mock).to have_received(:write)
        .with(hash_including(data: kind_of(String)))
        .exactly(count).times
    end
  end

  # Helper method to suppress output
  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(File.new('/dev/null', 'w'))
    yield
  ensure
    stream.reopen(old_stream)
  end
end
