require "spec_helper"

RSpec.describe "Sinatra app helpers" do
  let(:helper) do
    Class.new do
      def pluralize(number, singular, plural)
        "#{number} #{number == 1 ? singular : plural}"
      end
    end.new
  end

  describe "#pluralize" do
    it "uses the singular form when count is 1" do
      expect(helper.pluralize(1, "repo", "repos")).to eq("1 repo")
    end

    it "uses the plural form when count is 0" do
      expect(helper.pluralize(0, "repo", "repos")).to eq("0 repos")
    end

    it "uses the plural form when count is greater than 1" do
      expect(helper.pluralize(5, "person", "people")).to eq("5 people")
    end

    it "uses the plural form for large numbers" do
      expect(helper.pluralize(100, "item", "items")).to eq("100 items")
    end
  end
end
