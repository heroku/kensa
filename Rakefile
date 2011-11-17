desc 'Run all unit tests'
task :test do
  fork do
    #exec "ruby test/resources/server.rb > /dev/null 2>&1"
    exec "ruby test/resources/server.rb > test_log.txt 2>&1"
  end
  system "turn test"
  system "ps -ax | grep test/resources/server.rb | grep -v grep | awk '{print $1}' | xargs kill"
end

task :default => :test
