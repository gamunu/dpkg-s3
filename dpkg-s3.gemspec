# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'dpkg/s3'

Gem::Specification.new do |gem|
  gem.name        = 'dpkg-s3'
  gem.version     = Dpkg::S3::VERSION

  gem.author      = 'Gamunu Balagalla'
  gem.email       = 'gamunu@fastcode.io'
  gem.homepage    = 'https://github.com/gamunu/dpkg-s3'
  gem.summary     = 'Easily create and manage an APT repository on S3.'
  gem.description = gem.summary
  gem.license     = 'MIT'
  gem.executables = 'dpkg-s3'

  gem.files = Dir['**/*'].select { |d| d =~ %r{^(README|bin/|ext/|lib/)} }

  gem.required_ruby_version = '>= 2.4'

  gem.add_dependency 'aws-sdk-s3', '~> 1.93'
  gem.add_dependency 'thor',    '~> 1.1'
  gem.add_development_dependency 'minitest', '~> 5.14'
  gem.add_development_dependency 'rake', '~> 13'
  gem.add_development_dependency 'rubocop-minitest', '~> 0.11.1'
  gem.add_development_dependency 'rubocop-rake', '~> 0.5.1'
end
