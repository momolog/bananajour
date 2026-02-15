require "spec_helper"
require "socket"

# Load just the module methods we need without triggering bonjour/grit
# We test the class methods defined in lib/bananajour.rb
RSpec.describe Bananajour do
  describe ".version_array" do
    it "parses a version string into an integer array" do
      expect(Bananajour.version_array("1.7.10")).to eq([1, 7, 10])
    end

    it "handles single-component versions" do
      expect(Bananajour.version_array("3")).to eq([3])
    end

    it "handles two-component versions" do
      expect(Bananajour.version_array("2.1")).to eq([2, 1])
    end

    it "handles versions with leading zeros" do
      expect(Bananajour.version_array("01.02.03")).to eq([1, 2, 3])
    end
  end

  describe ".git_version_at_least?" do
    before do
      allow(Bananajour).to receive(:git_version).and_return("2.30.0")
    end

    it "returns true when current version equals required version" do
      expect(Bananajour.git_version_at_least?("2.30.0")).to be true
    end

    it "returns true when current version is greater" do
      expect(Bananajour.git_version_at_least?("2.29.0")).to be true
    end

    it "returns false when current version is less" do
      expect(Bananajour.git_version_at_least?("2.31.0")).to be false
    end

    it "handles versions of different lengths" do
      expect(Bananajour.git_version_at_least?("2.30")).to be true
      expect(Bananajour.git_version_at_least?("2.30.0.1")).to be false
    end

    it "compares major versions correctly" do
      expect(Bananajour.git_version_at_least?("1.99.99")).to be true
      expect(Bananajour.git_version_at_least?("3.0.0")).to be false
    end
  end

  describe ".host_name" do
    context "when bananajour.hostname is configured in git" do
      it "returns the configured hostname" do
        allow(Bananajour).to receive(:get_git_global_config).with("bananajour.hostname").and_return("custom.host")
        expect(Bananajour.host_name).to eq("custom.host")
      end
    end

    context "when bananajour.hostname is not configured" do
      before do
        allow(Bananajour).to receive(:get_git_global_config).with("bananajour.hostname").and_return("")
      end

      it "appends .local to a bare hostname" do
        allow(Socket).to receive(:gethostname).and_return("mycomputer")
        expect(Bananajour.host_name).to eq("mycomputer.local")
      end

      it "does not double-append .local" do
        allow(Socket).to receive(:gethostname).and_return("mycomputer.local")
        expect(Bananajour.host_name).to eq("mycomputer.local")
      end

      it "returns a FQDN as-is (more than one period)" do
        allow(Socket).to receive(:gethostname).and_return("host.example.com")
        expect(Bananajour.host_name).to eq("host.example.com")
      end
    end
  end
end
