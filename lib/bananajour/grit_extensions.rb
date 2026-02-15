# Ruby 3.2+ removed File.exists? and Dir.exists? but grit 1.1.1 still uses them.
def File.exists?(path) = File.exist?(path) unless File.respond_to?(:exists?)
def Dir.exists?(path) = Dir.exist?(path) unless Dir.respond_to?(:exists?)

# Grit's ruby1.9.rb only patches String#getord for RUBY_VERSION "1.9", so on Ruby 2.0+
# it falls back to aliasing [] which returns a String, not an Integer. Fix it for all
# modern Ruby versions.
class String
  def getord(offset) = self[offset].ord
end

Grit::Commit.class_eval do
  def ==(other)
    self.id == other.id
  end
end

Grit::Actor.class_eval do
  def gravatar_uri
    Bananajour.gravatar_uri(email)
  end
end
