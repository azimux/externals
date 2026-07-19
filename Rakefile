require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems/package_task'
require 'find'

require_relative "version"

root_dir = File.dirname(__FILE__)

$LOAD_PATH << File.join(root_dir, 'lib')

require File.join(root_dir, 'lib', 'externals', 'ext')

Rake::TestTask.new('test') do |task|
  task.libs = [File.expand_path('lib'),File.expand_path('test/support')]
  task.pattern = './test/test_*.rb'
  #task.warning = true
end

gem_specification = Gem::Specification.new do |specification|
  specification.name = 'ext'
  specification.version = Externals::VERSION
  specification.platform = Gem::Platform::RUBY
  specification.rubyforge_project = 'ext'

  specification.summary =
    %{Provides an SCM agnostic way to manage subprojects with a workflow similar
to the svn:externals feature of subversion.}
  specification.description =
    %{Provides an SCM agnostic way to manage subprojects with a workflow similar
to the scm:externals feature of subversion.

There are several other useful commands, such as init, touch_emptydirs, add_all,
export, status.  There's a tutorial at http://nopugs.com/ext-tutorial

The reason I made this project is that I was frustrated by two things:

1.  In my opinion, the workflow for svn:externals is far superior to
git-submodule.

2.  Even if git-submodule was as useful as svn:externals, I would still like a
uniform way to fetch all of the subprojects regardless of the SCM used to manage
the main project.}

  specification.author = "Miles Georgi"
  specification.email = "azimux@gmail.com"
  specification.homepage = "http://nopugs.com/ext-tutorial"

  specification.required_ruby_version = Externals::MINIMUM_RUBY_VERSION

  specification.test_files = FileList['test/test_*.rb', 'test/setup/*.gz']

  specification.bindir = "bin"
  specification.executables = ['ext']

  specification.license = "MPL-2.0"

  specification.files = Dir[
                             "bin/ext",
                             "lib/**/*",
                             "LICENSE*.txt",
                             "README*",
                             "CHANGELOG*",
                             "version.rb"
                           ]

  specification.require_paths = ["lib"]
end

Gem::PackageTask.new(gem_specification) do |package|
  package.need_zip = package.need_tar = false
end
