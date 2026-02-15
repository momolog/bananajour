#!/usr/bin/env ruby
# Runs a second bananajour instance with a fake identity on a different port,
# useful for testing Bonjour network discovery on a single machine.

lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "bananajour"
require "fileutils"

Thread.abort_on_exception = true

# Override identity and ports for the second instance
module Bananajour
  class << self
    def config
      @config = OpenStruct.new(
        name:  "Testy McTestface",
        email: "testy@example.com"
      )
    end

    def web_port
      9332
    end

    def path
      Pathname("/tmp/bananajour2")
    end
  end
end

# Set up the second instance's repo directory
Bananajour.setup! unless Bananajour.setup?

# Create a sample repo if none exist
if Bananajour.repositories.empty?
  repo_path = Bananajour.repositories_path.join("hello-world.git")
  unless repo_path.exist?
    work_dir = "/tmp/bananajour2-work"
    FileUtils.rm_rf(work_dir)
    FileUtils.mkdir_p(work_dir)

    system("git init --bare #{repo_path}", out: File::NULL, err: File::NULL)
    Dir.chdir(work_dir) do
      system("git init", out: File::NULL, err: File::NULL)
      system("git config user.email testy@example.com", out: File::NULL, err: File::NULL)
      system("git config user.name 'Testy McTestface'", out: File::NULL, err: File::NULL)
      File.write("README.md", "# Hello World\n\nA test repo from the second bananajour instance.")
      system("git add README.md", out: File::NULL, err: File::NULL)
      system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
      system("git remote add origin #{repo_path}", out: File::NULL, err: File::NULL)
      system("git push origin master 2>/dev/null || git push origin main", out: File::NULL, err: File::NULL)
    end
    puts "* Created sample repo: hello-world"
  end
end

# Start web server and bonjour advertiser (skip git daemon to avoid port conflict)
pids = []
at_exit do
  pids.each { |pid| Process.kill("TERM", pid) rescue nil }
  puts "\nStopped second instance."
end

puts "* Second bananajour instance: #{Bananajour.config.name}"
puts "* Repos in: #{Bananajour.repositories_path}"

pids << Bananajour.serve_web!
pids << Bananajour.advertise!

begin
  Process.waitall
rescue Interrupt
end
