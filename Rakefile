# ------------------------------------------------------------
# Git dependencies

namespace :git do
  desc 'Update engines'
  task :pull_stash_engine do
    stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
    sh "cd '#{stash_engine_path}' && git pull"
  end
end

task git_pull: ['git:pull_stash_engine']

# ------------------------------------------------------------
# RSpec

require 'rspec/core'
require 'rspec/core/rake_task'

namespace :spec do
  desc 'Run all unit tests'
  RSpec::Core::RakeTask.new(:unit) do |task|
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'unit/**/*_spec.rb'
  end

  desc 'Run all database tests'
  RSpec::Core::RakeTask.new(:db) do |task|
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'db/**/*_spec.rb'
  end

  desc 'Run unit and database tests as single suite (for coverage)'
  RSpec::Core::RakeTask.new(:unified) do |task|
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = '{db,unit}/**/*_spec.rb'
  end
end

desc 'Run all tests'
task spec: %w(spec:unit spec:db)

# ------------------------------------------------------------
# Coverage

# TODO: Get coverage to 100%, add to default tasks
desc 'Run all tests with coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec:unified'].invoke
end

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# Database

# Make sure we migrate the right environment
ENV['RAILS_ENV'] = ENV['STASH_ENV']

# require 'standalone_migrations'
# StandaloneMigrations::Tasks.load_tasks

# ------------------------------------------------------------
# Miscellaneous

task :debug_load_path do
  puts $LOAD_PATH
end

# ------------------------------------------------------------
# Defaults

# TODO: add coverage
desc 'Check code style, run unit tests'
task default: %i(git_pull spec rubocop)