require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'find'

root_dir = File.dirname(__FILE__)

$LOAD_PATH << File.join(root_dir, 'lib')

require File.join(root_dir, 'lib', 'externals', 'ext')

desc "Creates the starting repositories needed to run the tests.
If you plan on running the tests, you only need
 to run this once."
task :prep_test do
  Dir.chdir File.join(root_dir, 'test') do

    puts `rm -rf cleanreps`
    Dir.mkdir('cleanreps')
    Dir.chdir('cleanreps') do
      %w(redhillonrails_core foreign_key_migrations empty_plugin).each do |p|
        puts `cp ../setup/#{p}.svn.gz .`
        puts `gzip -d #{p}.svn.gz`
        puts `svnadmin create #{p}`
        puts `svnadmin load #{p} < #{p}.svn`
      end

      puts `git clone --bare git://github.com/azimux/engines.git engines.git`

      %w(acts_as_list ssl_requirement).each do |p|
        puts `git clone --bare git://github.com/rails/#{p}.git #{p}.git`
      end

      if File.exists? 'C:\\tmp\\rails'
        puts `cp -a C:\\tmp\\rails full_rails`
      elsif File.exists? '/tmp/rails'
        puts `cp -a /tmp/rails full_rails`
      else
        puts `git clone git://github.com/rails/rails.git full_rails`
      end
      puts `cp -a full_rails fake_rails`

      #let's make the repo smaller by removing all but 1 file from each
      #directory to save time
      Dir.chdir 'fake_rails' do
        puts `rm -rf .git`
        raise "something wrong with rm" if File.exists? '.git'
      end

      dirs = []
      Find.find('fake_rails') do |f|
        dirs << f if File.directory?(f)
      end

      dirs.each do |dir|
        files = Dir.entries(dir)

        Dir.chdir(dir) do
          files = files.select {|e|e != ".gitignore" && File.file?(e)}.sort
          files.shift #let's keep the first file in the list.
          files.each do |file|
            File.delete(file)
          end
        end
      end

      raise "why is rails already here?" if File.exists? 'rails.git'

      Dir.mkdir('rails.git')

      Dir.chdir('rails.git') do
        puts `git init --bare`
      end

      Dir.chdir 'fake_rails' do
        puts `git init`
        puts `git add .`
        puts `git commit -m "rails with all but 1 file per directory deleted"`
        puts `git push ../rails.git master`
      end
    end
  end
end

Rake::TestTask.new('test') do |task|
  task.libs = [File.expand_path('lib'),File.expand_path('test')]
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
to the svn:externals feature of subversion.  It's particularly useful for rails
projects that have some plugins managed by svn and some managed by git.}
  specification.description =
    %{Provides an SCM agnostic way to manage subprojects with a workflow similar
to the scm:externals feature of subversion.  It's particularly useful for rails
projects that have some plugins managed by svn and some managed by git.

For example, "ext install git://github.com/rails/rails.git" from within a rails
application directory will realize that this belongs in the vendor/rails folder.
It will also realize that this URL is a git repository and clone it into that
folder.

It will also add the vendor/rails folder to the ignore feature for the SCM of
the main project.  Let's say that the main project is being managed by
subversion.  In that case it adds "rails" to the svn:ignore property of the
vendor folder.  It also adds the URL to the .externals file so that when this
project is checked out via "ext checkout" it knows where to fetch the
subprojects.

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

  specification.test_files = FileList['test/test_*.rb']

  specification.bindir = "bin"
  specification.executables = ['ext']
  specification.default_executable = "ext"

  specification.files = ['Rakefile', 'README', 'MIT_LICENSE.txt', 'CHANGELOG'] +
    FileList['lib/**/*.rb']
  #specification.require_path = 'lib'
end

Rake::GemPackageTask.new(gem_specification) do |package|
  package.need_zip = package.need_tar = false
end