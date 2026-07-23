require "bundler/gem_tasks"
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems/package_task'

Rake::TestTask.new('test') do |task|
  # task.libs = [File.expand_path('lib'), File.expand_path('test/support')]
  task.pattern = './test/test_*.rb'
  #task.warning = true
end
