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

  gem.add_dependency "thor",    "~> 1.0.1"
  gem.add_dependency "aws-sdk-s3", "~> 1.64"
  gem.add_development_dependency "minitest", "~> 5.8"
  gem.add_development_dependency "rake", "~> 13"
end
