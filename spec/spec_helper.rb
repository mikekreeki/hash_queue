require 'bundler/setup'
require 'timeout'

require 'minitest/autorun'
require "minitest/reporters"

require 'hash_queue'


MiniTest::Reporters.use! MiniTest::Reporters::ProgressReporter.new
