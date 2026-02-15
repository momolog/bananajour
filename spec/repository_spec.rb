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

  describe "with a real git repository" do
    let(:tmp_bare_path) { Dir.mktmpdir("bananajour-test") + "/test-project.git" }
    let(:tmp_work_path) { Dir.mktmpdir("bananajour-work") }
    let(:repo) { described_class.new(tmp_bare_path) }

    before do
      system("git init --bare #{tmp_bare_path}", out: File::NULL, err: File::NULL)
      Dir.chdir(tmp_work_path) do
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.email test@test.com", out: File::NULL, err: File::NULL)
        system("git config user.name Test", out: File::NULL, err: File::NULL)
        File.write("README.md", "# Test Project")
        system("git add README.md", out: File::NULL, err: File::NULL)
        system("git commit -m 'initial commit'", out: File::NULL, err: File::NULL)
        system("git remote add origin #{tmp_bare_path}", out: File::NULL, err: File::NULL)
        system("git push origin master 2>/dev/null || git push origin main", out: File::NULL, err: File::NULL)
      end
    end

    after do
      FileUtils.rm_rf(tmp_bare_path)
      FileUtils.rm_rf(tmp_work_path)
    end

    it "returns a Rugged::Repository from #rugged_repo" do
      expect(repo.rugged_repo).to be_a(Rugged::Repository)
    end

    it "returns recent commits as CommitWrappers" do
      commits = repo.recent_commits
      expect(commits).not_to be_empty
      expect(commits.first).to be_a(Bananajour::CommitWrapper)
    end

    it "exposes commit accessors via CommitWrapper" do
      commit = repo.recent_commits.first
      expect(commit.id).to be_a(String)
      expect(commit.id.length).to eq(40)
      expect(commit.id_abbrev.length).to eq(7)
      expect(commit.short_message).to eq("initial commit")
      expect(commit.committed_date).to be_a(Time)
    end

    it "exposes author via ActorWrapper" do
      author = repo.recent_commits.first.author
      expect(author).to be_a(Bananajour::ActorWrapper)
      expect(author.name).to eq("Test")
      expect(author.email).to eq("test@test.com")
      expect(author.to_s).to eq("Test <test@test.com>")
    end

    it "returns heads as BranchWrappers" do
      h = repo.heads
      expect(h).not_to be_empty
      expect(h.first).to be_a(Bananajour::BranchWrapper)
      expect(h.first.name).to be_a(String)
      expect(h.first.commit).to be_a(Bananajour::CommitWrapper)
    end

    it "looks up a commit by SHA" do
      sha = repo.recent_commits.first.id
      commit = repo.commit(sha)
      expect(commit.id).to eq(sha)
      expect(commit.short_message).to eq("initial commit")
    end

    it "returns a readme_file with name and data" do
      rf = repo.readme_file
      expect(rf).not_to be_nil
      expect(rf.name).to eq("README.md")
      expect(rf.data).to eq("# Test Project")
    end

    it "returns diffs from CommitWrapper" do
      commit = repo.recent_commits.first
      patches = commit.diffs
      expect(patches).to be_an(Array)
      expect(patches).not_to be_empty
    end

    it "produces a valid to_hash for JSON API" do
      hash = repo.to_hash
      expect(hash["name"]).to eq("test-project")
      expect(hash["heads"]).to be_an(Array)
      expect(hash["recent_commits"]).to be_an(Array)
      expect(hash["recent_commits"].first["id"]).to be_a(String)
      expect(hash["recent_commits"].first["author"]).to have_key("name")
      expect(hash["recent_commits"].first["committed_date"]).to be_a(String)
    end
  end
end
