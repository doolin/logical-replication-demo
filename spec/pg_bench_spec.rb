# frozen_string_literal: true

require_relative '../lib/pg_bench'

RSpec.describe PGBench do
  describe '#default' do
    it 'returns the default pgbench command' do
      expect(described_class.new.default)
        .to eq('PGPASSWORD=foobar pgbench -h localhost -p 5435 -U postgres -T 60 -c 10 -j 3 publisher')
    end
  end

  describe '#run_default' do
    let(:pgbench) { PGBench.new }

    before do
      allow(pgbench).to receive(:bench_sys)
    end

    it 'calls bench_sys with default command' do
      default_command = "PGPASSWORD=foobar pgbench -h localhost -p 5435 -U postgres -T 60 -c 10 -j 3 publisher"
      pgbench.run_default

      expect(pgbench).to have_received(:bench_sys).with(default_command)
    end
  end
end
