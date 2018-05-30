$: << File.dirname(__FILE__)

require 'rake/testtask'
require 'lib/johac'
require "yard"

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test
