require "spec_helper"

RSpec.describe Bananajour::Bonjour::RepositoryBrowser do
  # Use allocate to skip initialize (which starts DNSSD browsing)
  let(:browser) { described_class.allocate }

  let(:local_person) do
    Bananajour::Bonjour::Person.new("Local User", "local@test.com", Bananajour.web_uri, "gravatar")
  end

  let(:remote_person) do
    Bananajour::Bonjour::Person.new("Remote User", "remote@test.com", "http://other.local:9331/", "gravatar")
  end

  describe "#repositories_similar_to" do
    it "excludes repos from the local bananajour instance" do
      local_repo = Bananajour::Bonjour::Repository.new("myrepo", "git://local.local/myrepo", local_person)
      remote_repo = Bananajour::Bonjour::Repository.new("myrepo", "git://other.local/myrepo", remote_person)
      allow(browser).to receive(:repositories).and_return([local_repo, remote_repo])

      result = browser.repositories_similar_to(double(name: "myrepo"))

      expect(result).to eq([remote_repo])
    end

    it "returns empty when only the local instance has the repo" do
      local_repo = Bananajour::Bonjour::Repository.new("myrepo", "git://local.local/myrepo", local_person)
      allow(browser).to receive(:repositories).and_return([local_repo])

      result = browser.repositories_similar_to(double(name: "myrepo"))

      expect(result).to be_empty
    end

    it "returns repos from remote instances with the same name" do
      remote_repo1 = Bananajour::Bonjour::Repository.new("myrepo", "git://a.local/myrepo", remote_person)
      remote_repo2 = Bananajour::Bonjour::Repository.new("other", "git://a.local/other", remote_person)
      allow(browser).to receive(:repositories).and_return([remote_repo1, remote_repo2])

      result = browser.repositories_similar_to(double(name: "myrepo"))

      expect(result).to eq([remote_repo1])
    end
  end
end
