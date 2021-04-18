# frozen_string_literal: true

require 'rake/testtask'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'

Rake::TestTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

RuboCop::RakeTask.new do |t|
  t.requires << 'rubocop-minitest'
end

task default: :test
