RSpec.describe Datemath do
  it "has a version number" do
    expect(Datemath::VERSION).not_to be nil
  end

  it "handles nonsense" do
    expect(Datemath::Parser.new("testing").parse).to eql(nil)
  end

  it "handles now" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now").parse).to eql(DateTime.now)
    end
  end

  it "handles single date" do
    expect(Datemath::Parser.new("2015-05-05T00:00:00").parse).to eql(DateTime.parse('2015-05-05T00:00:00'))
  end

  it "handles bad math expressions" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now||*asdaqwe").parse).to eql(DateTime.now)
    end
  end

  it "handles complex expressions" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now+1d").parse).to eql(DateTime.now + 1.day)
    end
  end

  it "handles complex expression with multiple digits" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now+12d").parse).to eql(DateTime.now + 12.day)
    end
  end

  it "handles complex expression with ms unit" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now+1000ms").parse).to eql(DateTime.now + 1.seconds)
    end
  end

  it "handles multiple operations" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now+1d-1m").parse).to eql(DateTime.now + 1.day - 1.minute)
    end
  end

  it "handles rounding" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now+1d-1m/d").parse).to eql((DateTime.now + 1.day - 1.minute).beginning_of_day)
    end
  end

  it "handles anchoring dates" do
    expect(Datemath::Parser.new("2015-05-05T00:00:00||+1d-1m").parse).to eql(DateTime.parse("2015-05-05T00:00:00") + 1.day - 1.minute)
  end

  it "handles rounding up two digit numbers" do
    Timecop.freeze(DateTime.now) do
      expect(Datemath::Parser.new("now/12").parse).to eql(DateTime.now)
    end
  end
end
