#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/reporters'

# Configure test output
Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new,
  Minitest::Reporters::JUnitReporter.new('test/reports')
]

# Add the fastlane directory to the load path
$LOAD_PATH.unshift(File.expand_path('..', __dir__))

# Require all test files
Dir[File.expand_path('*_test.rb', __dir__)].each { |file| require file }

puts "Test files loaded:"
Dir[File.expand_path('*_test.rb', __dir__)].each { |file| puts "  - #{File.basename(file)}" }

puts "Running Version Manager Tests..."
puts "================================"