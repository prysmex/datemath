RSpec.describe Datemath do
  it "has a version number" do
    expect(Datemath::VERSION).not_to be nil
  end

  it "handles nonsense" do
    expect(Datemath::Parser.new.parse("testing")).to eql(nil)
  end

  it "handles now" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now")).to eql(DateTime.now)
    end
  end

  it "handles single date" do
    expect(Datemath::Parser.new.parse("2015-05-05T00:00:00")).to eql(DateTime.parse('2015-05-05T00:00:00'))
  end

  it "handles bad math expressions" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now||*asdaqwe")).to eql(DateTime.now)
    end
  end

  it "handles complex expressions" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now+1d")).to eql(DateTime.now + 1.day)
    end
  end

  it "handles complex expression with multiple digits" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now+12d")).to eql(DateTime.now + 12.day)
    end
  end

  it "handles complex expression with ms unit" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now+1000ms")).to eql(DateTime.now + 1.seconds)
    end
  end

  it "handles multiple operations" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now+1d-1m")).to eql(DateTime.now + 1.day - 1.minute)
    end
  end

  it "handles rounding" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now+1d-1m/d")).to eql((DateTime.now + 1.day - 1.minute).beginning_of_day)
    end
  end

  it "handles anchoring dates" do
    expect(Datemath::Parser.new.parse("2015-05-05T00:00:00||+1d-1m")).to eql(DateTime.parse("2015-05-05T00:00:00") + 1.day - 1.minute)
  end

  it "handles rounding up two digit numbers" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new.parse("now/12")).to eql(DateTime.now)
    end
  end
end
