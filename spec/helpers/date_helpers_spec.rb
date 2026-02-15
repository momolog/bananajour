require "spec_helper"

RSpec.describe Bananajour::DateHelpers do
  let(:helper) { Object.new.extend(described_class) }

  describe "#distance_of_time_in_words" do
    def distance(seconds, include_seconds: false)
      from = Time.new(2024, 1, 1, 0, 0, 0)
      to = from + seconds
      helper.distance_of_time_in_words(from, to, include_seconds)
    end

    context "without include_seconds" do
      it "returns 'less than a minute' for 0 seconds" do
        expect(distance(0)).to eq("less than a minute")
      end

      it "returns 'less than a minute' for 29 seconds" do
        expect(distance(29)).to eq("less than a minute")
      end

      it "returns '1 minute' for 30 seconds" do
        expect(distance(30)).to eq("1 minute")
      end

      it "returns '1 minute' for 89 seconds" do
        expect(distance(89)).to eq("1 minute")
      end

      it "returns '2 minutes' for 90 seconds" do
        expect(distance(90)).to eq("2 minutes")
      end

      it "returns '44 minutes' for 44 minutes" do
        expect(distance(44 * 60)).to eq("44 minutes")
      end

      it "returns 'about 1 hour' for 45 minutes" do
        expect(distance(45 * 60)).to eq("about 1 hour")
      end

      it "returns 'about 1 hour' for 89 minutes" do
        expect(distance(89 * 60)).to eq("about 1 hour")
      end

      it "returns 'about 2 hours' for 90 minutes" do
        expect(distance(90 * 60)).to eq("about 2 hours")
      end

      it "returns 'about 24 hours' for 23 hours 59 minutes" do
        expect(distance(23 * 3600 + 59 * 60)).to eq("about 24 hours")
      end

      it "returns '1 day' for 24 hours" do
        expect(distance(24 * 3600)).to eq("1 day")
      end

      it "returns '1 day' for 47 hours 59 minutes" do
        expect(distance(47 * 3600 + 59 * 60)).to eq("1 day")
      end

      it "returns '2 days' for 48 hours" do
        expect(distance(48 * 3600)).to eq("2 days")
      end

      it "returns '29 days' for 29 days" do
        expect(distance(29 * 86400)).to eq("29 days")
      end

      it "returns 'about 1 month' for 30 days" do
        expect(distance(30 * 86400)).to eq("about 1 month")
      end

      it "returns 'about 1 month' for 59 days" do
        expect(distance(59 * 86400)).to eq("about 1 month")
      end

      it "returns '2 months' for 60 days" do
        expect(distance(60 * 86400)).to eq("2 months")
      end

      it "returns 'about 1 year' for 365 days" do
        expect(distance(365 * 86400)).to eq("about 1 year")
      end

      it "returns 'over 2 years' for 730 days" do
        expect(distance(730 * 86400)).to eq("over 2 years")
      end

      it "returns 'over 5 years' for 5 years" do
        expect(distance(5 * 365.25 * 86400)).to eq("over 5 years")
      end
    end

    context "with include_seconds" do
      it "returns 'less than 5 seconds' for 0..4 seconds" do
        expect(distance(0, include_seconds: true)).to eq("less than 5 seconds")
        expect(distance(4, include_seconds: true)).to eq("less than 5 seconds")
      end

      it "returns 'less than 10 seconds' for 5..9 seconds" do
        expect(distance(5, include_seconds: true)).to eq("less than 10 seconds")
        expect(distance(9, include_seconds: true)).to eq("less than 10 seconds")
      end

      it "returns 'less than 20 seconds' for 10..19 seconds" do
        expect(distance(10, include_seconds: true)).to eq("less than 20 seconds")
        expect(distance(19, include_seconds: true)).to eq("less than 20 seconds")
      end

      it "returns 'half a minute' for 20..39 seconds" do
        expect(distance(20, include_seconds: true)).to eq("half a minute")
        expect(distance(39, include_seconds: true)).to eq("half a minute")
      end

      it "returns 'less than a minute' for 40..59 seconds" do
        expect(distance(40, include_seconds: true)).to eq("less than a minute")
        expect(distance(59, include_seconds: true)).to eq("less than a minute")
      end

      it "returns '1 minute' for 60..89 seconds" do
        expect(distance(60, include_seconds: true)).to eq("1 minute")
        expect(distance(89, include_seconds: true)).to eq("1 minute")
      end
    end

    it "handles negative time differences (absolute value)" do
      from = Time.new(2024, 1, 1, 1, 0, 0)
      to = Time.new(2024, 1, 1, 0, 0, 0)
      expect(helper.distance_of_time_in_words(from, to)).to eq("about 1 hour")
    end
  end

  describe "#time_ago_in_words" do
    it "delegates to distance_of_time_in_words with Time.now as to_time" do
      from_time = Time.now - 3600
      result = helper.time_ago_in_words(from_time)
      expect(result).to eq("about 1 hour")
    end
  end
end
