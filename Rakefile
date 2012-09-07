#!/usr/bin/env rake

$:.unshift File.expand_path(File.dirname(__FILE__) + '/lib')

require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = true
end

desc "Run tests"
task :default => :test