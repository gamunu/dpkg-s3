$:.unshift File.expand_path("../lib", __FILE__)
require "dpkg/s3"

Gem::Specification.new do |gem|
  gem.name        = "dpkg-s3"
  gem.version     = Dpkg::S3::VERSION

  gem.author      = "Gamunu Balagalla"
  gem.email       = "gamunu.balagalla@outlook.com"
  gem.homepage    = "https://github.com/gamunu/dpkg-s3"
  gem.summary     = "Easily create and manage an APT repository on S3."
  gem.description = gem.summary
  gem.license     = "MIT"
  gem.executables = "dpkg-s3"

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|ext/|lib/)} }

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency "thor",    "~> 0.19.0"
  gem.add_dependency "aws-sdk", "~> 2"
  gem.add_development_dependency "minitest", "~> 5"
  gem.add_development_dependency "rake", "~> 11"
end
