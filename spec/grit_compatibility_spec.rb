require "spec_helper"

RSpec.describe "Grit Ruby 4.0 compatibility patches" do
  describe "File.exists?" do
    it "is available as an alias for File.exist?" do
      expect(File).to respond_to(:exists?)
    end

    it "returns the same result as File.exist?" do
      expect(File.exists?(__FILE__)).to eq(File.exist?(__FILE__))
      expect(File.exists?("/nonexistent/path")).to eq(File.exist?("/nonexistent/path"))
    end
  end

  describe "Dir.exists?" do
    it "is available as an alias for Dir.exist?" do
      expect(Dir).to respond_to(:exists?)
    end

    it "returns the same result as Dir.exist?" do
      expect(Dir.exists?(__dir__)).to eq(Dir.exist?(__dir__))
      expect(Dir.exists?("/nonexistent/path")).to eq(Dir.exist?("/nonexistent/path"))
    end
  end

  describe "String#getord" do
    it "returns the integer byte value at the given offset" do
      expect("A".getord(0)).to eq(65)
      expect("AB".getord(1)).to eq(66)
    end

    it "returns an Integer, not a String" do
      expect("x".getord(0)).to be_a(Integer)
    end
  end
end
