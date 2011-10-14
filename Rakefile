$:.unshift File.dirname(__FILE__)
require "bundler/gem_tasks"

desc 'Run all unit tests'
task :test do
  puts require "test/helper"
  Dir["test/*_test.rb"].each do |test_file|
    require test_file
  end
end

task :default => :test
