require 'bundler/gem_tasks'

desc 'Run all unit tests'
task :test do
  pid = fork do
    exec "ruby test/resources/server.rb > test_log.txt 2>&1"
  end
  system "turn test"
  Process.kill 'INT', pid 
end

task :default => :test
