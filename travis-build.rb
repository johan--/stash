#!/usr/bin/env ruby

require 'bundler'
require 'pathname'
require 'time'

# ########################################
# Constants

PROJECTS = %w[
  stash-wrapper
  stash-harvester
  stash-sword
  stash-merritt
  stash_engine
  stash_engine_specs
  stash_discovery
  stash_datacite
  stash_datacite_specs
].freeze

STASH_ROOT = Pathname.new(__dir__)

TRAVIS_PREP_SH = 'travis-prep.sh'.freeze

# ########################################
# Helper methods

def travis_fold(group, &block)
  puts "travis_fold:start:#{group}"
  yield
ensure
  puts "travis_fold:end:#{group}"
end

def dir_for(project)
  STASH_ROOT + project
end

def in_project(project, &block)
  Dir.chdir(dir_for(project)) { yield }
end

# ########################################
# Build steps

def run_bundle_install
  Bundler.with_clean_env { return system('bundle install') }
end

def bundle(project)
  travis_fold("bundle-#{project}") do
    in_project(project) { return run_bundle_install }
  end
rescue => e
  $stderr.puts(e)
  return false
end

def run_travis_prep_if_present
  return true unless File.exists?(TRAVIS_PREP_SH)
  travis_fold("prepare-#{project}") do
    unless FileTest.executable?(TRAVIS_PREP_SH)
      $stderr.puts("prepare failed: #{File.absolute_path(TRAVIS_PREP_SH)} is not executable")
      return false
    end
    system(TRAVIS_PREP_SH, err: :out)
  end
end

def prepare(project)
  in_project(project) { return run_travis_prep_if_present }
rescue => e
  $stderr.puts(e)
  return false
end

def run_rake
  system('bundle exec rake')
end

def build(project)
  travis_fold("build-#{project}") do
    in_project(project) { return run_rake }
  end
rescue => e
  $stderr.puts(e)
  return false
end

def bundle_all
  PROJECTS.each do |p|
    bundle_ok = bundle(p)
    $stderr.puts("#{p} bundle failed") unless bundle_ok
    exit(1) unless bundle_ok
  end
  true
end

def build_all
  build_succeeded = []
  build_failed = []
  PROJECTS.each do |p|
    build_ok = build(p)
    build_succeeded << p if build_ok
    build_failed << p unless build_ok
    $stderr.puts("#{p} build failed") unless build_ok
  end

  unless build_succeeded.empty?
    $stderr.puts("The following projects built successfully: #{build_succeeded.join(', ')}")
  end
  unless build_failed.empty?
    $stderr.puts("The following projects failed to build: #{build_failed.join(', ')}")
    exit(1)
  end
end

# ########################################
# Build commands

bundle_all
build_all
