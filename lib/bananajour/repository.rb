require 'rugged'
require 'pathname'
require 'ostruct'
require 'delegate'

module Bananajour

  class ActorWrapper
    def initialize(hash)
      @hash = hash
    end
    def name = @hash[:name]
    def email = @hash[:email]
    def to_s = "#{name} <#{email}>"
    def gravatar_uri = Bananajour.gravatar_uri(email)
  end

  class CommitWrapper < SimpleDelegator
    def initialize(commit, repo)
      super(commit)
      @repo = repo
    end
    def id = oid
    def id_abbrev = oid[0..6]
    def short_message = message.lines.first&.chomp || ""
    def committed_date = time
    def author
      ActorWrapper.new(__getobj__.author)
    end
    def ==(other)
      other.respond_to?(:oid) && self.oid == other.oid
    end
    def diffs
      if parents.empty?
        # First commit — diff against empty tree
        empty_tree = Rugged::Tree.empty(@repo)
        empty_tree.diff(tree).patches
      else
        parents.first.tree.diff(tree).patches
      end
    end
    def to_hash
      {
        "id" => oid,
        "message" => short_message,
        "author" => {"name" => author.name, "email" => author.email},
        "committed_date" => time.to_s
      }
    end
  end

  class BranchWrapper
    def initialize(branch, repo)
      @branch = branch
      @repo = repo
    end
    def name = @branch.name
    def commit
      CommitWrapper.new(@branch.target, @repo)
    end
  end

  class Repository
    def self.for_name(name)
      new(Bananajour.repositories_path.join(name + ".git"))
    end
    def self.html_id(name)
      name.gsub(/[^A-Za-z-]+/, '').downcase
    end
    def initialize(path)
      @path = Pathname(path)
    end
    def ==(other)
      other.respond_to?(:path) && self.path == other.path
    end
    attr_reader :path
    def exist?
      path.exist?
    end
    def init!
      path.mkpath
      Dir.chdir(path) { `git init --bare` }
    end
    def name
      dirname.sub(".git",'')
    end
    def html_id
      self.class.html_id(name)
    end
    def dirname
      path.split.last.to_s
    end
    def to_s
      name
    end
    def uri
      Bananajour.git_uri + dirname
    end
    def web_uri
      Bananajour.web_uri + "#" + html_id
    end
    def rugged_repo
      @rugged_repo ||= Rugged::Repository.new(path.to_s)
    end
    def heads
      rugged_repo.branches.each(:local).map { |b| BranchWrapper.new(b, rugged_repo) }
    rescue Rugged::ReferenceError
      []
    end
    def recent_commits
      @commits ||= begin
        walker = Rugged::Walker.new(rugged_repo)
        walker.push(rugged_repo.head.target_id)
        walker.map { |c| CommitWrapper.new(c, rugged_repo) }.first(10)
      rescue Rugged::ReferenceError
        []
      end
    end
    def commit(sha)
      obj = rugged_repo.lookup(sha)
      CommitWrapper.new(obj, rugged_repo)
    end
    def readme_file
      target = rugged_repo.head.target
      tree = target.tree
      entry = tree.find { |e| e[:name] =~ /readme/i }
      return nil unless entry
      blob = rugged_repo.lookup(entry[:oid])
      OpenStruct.new(name: entry[:name], data: blob.content)
    rescue Rugged::ReferenceError
      nil
    end
    def rendered_readme
      rf = readme_file
      return nil unless rf
      case File.extname(rf.name)
      when /\.md/i, /\.markdown/i
        require 'rdiscount'
        RDiscount.new(rf.data).to_html
      when /\.textile/i
        require 'redcloth'
        RedCloth.new(rf.data).to_html(:textile)
      end
    rescue LoadError
      ""
    end
    def remove!
      path.rmtree
    end
    def to_hash
      h = heads
      {
        "name" => name,
        "html_friendly_name" => html_id,
        "html_id" => html_id,
        "uri" => uri,
        "heads" => h.map { |b| b.name },
        "recent_commits" => recent_commits.collect do |c|
          c.to_hash.merge(
            "head" => (head = h.find { |b| b.commit == c }) && head.name,
            "gravatar" => c.author.gravatar_uri
          )
        end,
        "bananajour" => Bananajour.to_hash
      }
    end
  end
end
