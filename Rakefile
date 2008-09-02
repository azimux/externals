require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

Rake::TestTask.new('test') do |t|
  t.libs = [File.expand_path('lib'),File.expand_path('test')]
  t.pattern = './test/test_*.rb'
  t.warning = true
end