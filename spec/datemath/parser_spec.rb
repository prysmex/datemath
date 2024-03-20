# frozen_string_literal: true

# now.iso8601(9)

offset = DateTime.now.formatted_offset

RSpec.describe Datemath::Parser do
  let(:anchor) { "2024-03-20T00:24:33.017468000#{offset}" }

  around do |ex|
    Timecop.freeze(DateTime.parse(anchor)) do
      ex.run
    end
  end

  describe '.new' do
    it 'allows no args' do
      expect { described_class.new.parse }.not_to raise_error(ArgumentError)
    end
  end

  describe '.build_duration' do
    multiple = 2
    values = {
      'y' => 31_556_952.0,
      'M' => 2_629_746.0,
      'w' => 604_800.0,
      'd' => 86_400.0,
      'h' => 3600.0,
      'm' => 60.0,
      's' => 1.0,
      'ms' => 0.001
    }

    Datemath::Parser::UNITS.each do |unit|
      it "build_duration for #{unit}" do
        expect(described_class.build_duration(multiple, unit).to_f).to eql(values[unit] * multiple)
      end
    end
  end

  describe '.num?' do
    it 'returns true for integers' do
      expect(described_class.num?('1')).to be(true)
    end

    it 'returns false for other strings' do
      expect(described_class.num?('a')).to be(false)
    end
  end

  describe '#parse' do
    it 'handles now string' do
      expect(described_class.new('now').parse).to eql(DateTime.now)
    end

    it 'handles ISO8601 string' do
      expect(described_class.new(anchor).parse).to eql(DateTime.parse(anchor))
    end

    describe 'bad inputs' do
      it 'handles nil' do
        expect(described_class.new.parse).to be_nil
      end

      it 'handles nonsense' do
        expect(described_class.new('testing').parse).to be_nil
      end

      it 'returns nil with operator besides [+-/]' do
        expect(described_class.new('now&1d').parse).to be_nil
      end

      it 'returns nil with incorrect unit' do
        expect(described_class.new('now+5f').parse).to be_nil
      end

      it 'returns nil if rounding unit is not 1' do
        expect(described_class.new('now/2y').parse).to be_nil
      end

      it 'returns nil if rounding unit is float' do
        expect(described_class.new('now/0.5y').parse).to be_nil
      end

      it 'returns nil if unit is missing' do # rubocop:disable RSpec/MultipleExpectations
        expect(described_class.new('now-0').parse).to be_nil
        expect(described_class.new('now-00').parse).to be_nil
        expect(described_class.new('now-000').parse).to be_nil
      end

      it 'handles bad math expressions' do
        expect(described_class.new('now||*asdaqwe').parse).to be_nil
      end
    end

    describe 'subtraction' do
      [5, 12, 247].each do |quantity|
        Datemath::Parser::UNITS.each do |unit|
          it "returns #{quantity} #{unit} ago" do
            expect(described_class.new("now-#{quantity}#{unit}").parse).to(
              eql(DateTime.now - described_class.build_duration(quantity, unit))
            )
          end

          it "returns #{quantity} #{unit} before anchor" do
            expect(described_class.new("#{anchor}||-#{quantity}#{unit}").parse).to(
              eql(DateTime.parse(anchor) - described_class.build_duration(quantity, unit))
            )
          end
        end
      end
    end

    describe 'addition' do
      [5, 12, 247].each do |quantity|
        Datemath::Parser::UNITS.each do |unit|
          it "returns #{quantity} #{unit} from now" do
            expect(described_class.new("now+#{quantity}#{unit}").parse).to(
              eql(DateTime.now + described_class.build_duration(quantity, unit))
            )
          end

          it "returns #{quantity} #{unit} after anchor" do
            expect(described_class.new("#{anchor}||+#{quantity}#{unit}").parse).to(
              eql(DateTime.parse(anchor) + described_class.build_duration(quantity, unit))
            )
          end
        end
      end
    end

    describe 'rounding down' do
      # now.iso8601(9)

      values = {
        'y' => "2024-01-01T00:00:00.000000000#{offset}",
        'M' => "2024-03-01T00:00:00.000000000#{offset}",
        'w' => "2024-03-18T00:00:00.000000000#{offset}",
        'd' => "2024-03-20T00:00:00.000000000#{offset}",
        'h' => "2024-03-20T00:00:00.000000000#{offset}",
        'm' => "2024-03-20T00:24:00.000000000#{offset}",
        's' => "2024-03-20T00:24:33.000000000#{offset}",
        'ms' => "2024-03-20T00:24:33.017000000#{offset}"
      }

      Datemath::Parser::UNITS.each do |unit|
        it "rounds down to #{unit}" do
          expect(described_class.new("now/#{unit}").parse).to eql(DateTime.parse(values[unit]))
        end
      end
    end

    describe 'rounding up' do
      # now.iso8601(9)

      values = {
        'y' => "2024-12-31T23:59:59.999999999#{offset}",
        'M' => "2024-03-31T23:59:59.999999999#{offset}",
        'w' => "2024-03-24T23:59:59.999999999#{offset}",
        'd' => "2024-03-20T23:59:59.999999999#{offset}",
        'h' => "2024-03-20T00:59:59.999999999#{offset}",
        'm' => "2024-03-20T00:24:59.999999999#{offset}",
        's' => "2024-03-20T00:24:33.999999999#{offset}",
        'ms' => "2024-03-20T00:24:33.017999999#{offset}"
      }

      Datemath::Parser::UNITS.each do |unit|
        it "rounds down to #{unit}" do
          expect(described_class.new("now/#{unit}").parse(round_up: true)).to eql(DateTime.parse(values[unit]))
        end
      end
    end

    it 'handles multiple operations' do
      expect(described_class.new('now+1d-1m').parse).to eql(DateTime.now + 1.day - 1.minute)
    end

    it 'handles rounding' do
      expect(described_class.new('now+1d-1m/d').parse).to eql((DateTime.now + 1.day - 1.minute).beginning_of_day)
    end

    it 'handles anchoring dates' do
      expect(described_class.new('2015-05-05T00:00:00||+1d-1m').parse).to(
        eql(DateTime.parse('2015-05-05T00:00:00') + 1.day - 1.minute)
      )
    end
  end
end
