ENV['RACK_ENV'] = 'test'

require "spec_helper"
require "rack/test"

# Add sinatra paths so we can load the app and mock browsers
$LOAD_PATH.unshift File.expand_path("../../sinatra/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../sinatra", __dir__)

# Load mock bonjour browsers before the app (same as development mode)
require "mock_browsers"

require "app"

RSpec.describe "GET /", type: :request do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context "with no repositories" do
    before do
      allow(Bananajour).to receive(:repositories).and_return([])
    end

    it "returns 200" do
      get "/"
      expect(last_response.status).to eq(200)
    end

    it "renders the page title" do
      get "/"
      expect(last_response.body).to include("Bananajour")
    end

    it "shows the 'Add a project' welcome text" do
      get "/"
      expect(last_response.body).to include("Add a project")
      expect(last_response.body).to include("bananajour init")
    end
  end

  context "with a repository" do
    let(:tmp_repo_path) { Dir.mktmpdir("bananajour-test") + "/test-project.git" }
    let(:tmp_work_path) { Dir.mktmpdir("bananajour-work") }

    before do
      # Create a bare repo with a commit containing a README
      system("git init --bare #{tmp_repo_path}", out: File::NULL, err: File::NULL)
      Dir.chdir(tmp_work_path) do
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.email test@test.com", out: File::NULL, err: File::NULL)
        system("git config user.name Test", out: File::NULL, err: File::NULL)
        File.write("README.md", "# Test Project")
        system("git add README.md", out: File::NULL, err: File::NULL)
        system("git commit -m 'initial'", out: File::NULL, err: File::NULL)
        system("git remote add origin #{tmp_repo_path}", out: File::NULL, err: File::NULL)
        system("git push origin master 2>/dev/null || git push origin main", out: File::NULL, err: File::NULL)
      end

      repo = Bananajour::Repository.new(tmp_repo_path)
      allow(Bananajour).to receive(:repositories).and_return([repo])
    end

    after do
      FileUtils.rm_rf(tmp_repo_path)
      FileUtils.rm_rf(tmp_work_path)
    end

    it "returns 200 and renders the repository" do
      get "/"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("test-project")
    end

    it "includes JSONP timeout handling so network spinners don't spin forever" do
      get "/"
      body = last_response.body
      expect(body).to include("timeout")
      expect(body).to include("error")
    end
  end
end
