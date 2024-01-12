# frozen_string_literal: true

require_relative '../lib/pg_bench'

RSpec.describe PGBench do
  subject(:pgbench) { described_class.new(default_options) }

  let(:default_options) { {} }

  describe '#initialize' do
    context 'without options' do
      it 'initializes with default options' do
        expect(pgbench.options).to eq(default_options)
      end

      # Add more tests for default initializations...
    end

    context 'with custom options' do
      subject(:pgbench_with_options) { described_class.new(custom_options) }

      let(:custom_options) { { duration: 60, clients: 5 } }

      it 'initializes with custom options' do
        expect(pgbench_with_options.options).to eq(custom_options)
      end

      # Add more tests for custom initializations...
    end
  end

  describe '#pgbench' do
    it 'returns a valid pgbench command' do
      expected = <<~CMD
        PGPASSWORD=foobar pgbench \\
          -h localhost \\
          -p 5435 \\
          -U postgres \\
          -s 10 \\
          -T 120 \\
          -c 10 \\
          -j 3 \\
          publisher --log
      CMD

      expect(pgbench.pgbench).to eq(expected)
    end
  end

  # Additional tests for #pgbench_custom, #pulse, #custom, etc.
end
