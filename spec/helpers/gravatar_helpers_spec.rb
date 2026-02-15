require "spec_helper"
require "digest/md5"

RSpec.describe Bananajour::GravatarHelpers do
  let(:helper) { Object.new.extend(described_class) }

  describe "#gravatar_uri" do
    it "returns a Gravatar URL with the MD5 hash of the email" do
      email = "test@example.com"
      expected_hash = Digest::MD5.hexdigest(email)
      expect(helper.gravatar_uri(email)).to eq("http://gravatar.com/avatar/#{expected_hash}.png")
    end

    it "produces correct MD5 for a known test vector" do
      # Known MD5: MD5("") = d41d8cd98f00b204e9800998ecf8427e
      expect(helper.gravatar_uri("")).to eq("http://gravatar.com/avatar/d41d8cd98f00b204e9800998ecf8427e.png")
    end

    it "is case-sensitive (Gravatar recommends lowercase, but we hash as-is)" do
      lower = helper.gravatar_uri("user@example.com")
      upper = helper.gravatar_uri("User@Example.com")
      expect(lower).not_to eq(upper)
    end
  end
end
