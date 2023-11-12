# frozen_string_literal: true

require_relative '../lib/pg_sampler'

RSpec.describe PGSampler do
  subject(:sampler) { described_class.new }

  let(:mock_pg_conn) { instance_double(PG::Connection) }
  let(:mock_http) { instance_double(Net::HTTP) }
  let(:mock_response) { instance_double(Net::HTTPResponse, body: 'Success') }
  let(:locks_data) { ['locks,host=localhost,database=publisher user=,value=1'] }

  before do
    allow(PG).to receive(:connect).and_return(mock_pg_conn)
    allow(mock_pg_conn).to receive(:exec_params).and_return(locks_data)
    allow(mock_pg_conn).to receive(:close)

    allow(Net::HTTP).to receive(:start).and_yield(mock_http)
    allow(mock_http).to receive(:request).and_return(mock_response)
  end

  xdescribe '#run' do
    it 'connects to PostgreSQL' do
      sampler.run
      expect(PG).to have_received(:connect).with(sampler.pg_options)
    end

    it 'retrieves lock data and writes to InfluxDB' do
      sampler.run
      expect(mock_pg_conn).to have_received(:exec_params).once
      expect(mock_http).to have_received(:request).once
    end

    it 'closes the PG connection' do
      sampler.run
      expect(mock_pg_conn).to have_received(:close).once
    end
  end

  describe '#get_pg_locks' do
    it 'executes the correct SQL query' do
      allow(sampler).to receive(:connect_to_db).and_return(mock_pg_conn)
      sampler.send(:get_pg_locks, mock_pg_conn)
      expect(mock_pg_conn).to have_received(:exec_params).with(an_instance_of(String),
                                                               array_including(sampler.pg_options[:host],
                                                                               sampler.pg_options[:dbname]))
    end
  end

  describe '#write_to_influx' do
    it 'sends a POST request to the InfluxDB write API' do
      sampler.send(:write_to_influx, locks_data)
      expect(Net::HTTP).to have_received(:start).once
      expect(mock_http).to have_received(:request).with(an_instance_of(Net::HTTP::Post))
    end
  end
end
