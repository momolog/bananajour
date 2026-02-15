require "spec_helper"
require "bananajour/repository"

RSpec.describe Bananajour::Repository do
  describe ".html_id" do
    it "lowercases the name" do
      expect(described_class.html_id("MyRepo")).to eq("myrepo")
    end

    it "strips non-alpha non-dash characters" do
      expect(described_class.html_id("my-repo_123")).to eq("my-repo")
    end

    it "strips dots and spaces" do
      expect(described_class.html_id("my.repo name")).to eq("myreponame")
    end

    it "handles names that are entirely special characters" do
      expect(described_class.html_id("123_456")).to eq("")
    end

    it "preserves dashes" do
      expect(described_class.html_id("my-cool-repo")).to eq("my-cool-repo")
    end
  end

  describe "#name" do
    it "strips .git from the directory name" do
      repo = described_class.new("/path/to/my-project.git")
      expect(repo.name).to eq("my-project")
    end

    it "returns directory name as-is if no .git suffix" do
      repo = described_class.new("/path/to/my-project")
      expect(repo.name).to eq("my-project")
    end
  end

  describe "#==" do
    it "returns true for repos with the same path" do
      repo1 = described_class.new("/path/to/repo.git")
      repo2 = described_class.new("/path/to/repo.git")
      expect(repo1).to eq(repo2)
    end

    it "returns false for repos with different paths" do
      repo1 = described_class.new("/path/to/repo1.git")
      repo2 = described_class.new("/path/to/repo2.git")
      expect(repo1).not_to eq(repo2)
    end

    it "returns false when compared to an object without #path" do
      repo = described_class.new("/path/to/repo.git")
      expect(repo).not_to eq("not a repo")
    end
  end

  describe "#uri" do
    it "constructs a git:// URI from Bananajour.git_uri and dirname" do
      allow(Bananajour).to receive(:git_uri).and_return("git://myhost.local/")
      repo = described_class.new("/repos/my-project.git")
      expect(repo.uri).to eq("git://myhost.local/my-project.git")
    end
  end

  describe "#web_uri" do
    it "constructs a web URI with html_id as fragment" do
      allow(Bananajour).to receive(:web_uri).and_return("http://myhost.local:9331/")
      repo = described_class.new("/repos/my-project.git")
      expect(repo.web_uri).to eq("http://myhost.local:9331/#my-project")
    end
  end

  describe "#html_id" do
    it "delegates to .html_id with the repo name" do
      repo = described_class.new("/repos/My-Project_2.git")
      expect(repo.html_id).to eq(described_class.html_id("My-Project_2"))
    end
  end
end
