require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.verbose = true
  t.test_files = FileList["test/*_test.rb"]
end

desc 'Start the server'
task :start do
  fork { exec "ruby test/resources/server.rb > test_log.txt 2>&1" }
end

desc 'Stop the server'
task :stop do
  system "ps -ax | grep test/resources/server.rb | grep -v grep | awk '{print $1}' | xargs kill"
end

task :default => [:start, :test, :stop]
