require 'test/unit'
require 'fileutils'

module Externals
  TestCase = Test::Unit::TestCase
  module ExtTestCase
    include FileUtils

    protected

    def mark_dirty file
      File.open working_file_name(file), "w" do |file|
        file.puts "dirty"
      end
    end

    def unmark_dirty file
      File.delete working_file_name(file)
    end

    def working_file_name file
      ".working_#{file}"
    end

    def dirty?(file)
      File.exists? working_file_name(file)
    end

    def delete_if_dirty file
      if File.exists? file
        if dirty?(file)
          `rm -r #{file}`
          raise unless $? == 0
        end
      end
    end

    def initialize_test_git_repository
      scm = 'git'
      Dir.chdir(File.join(File.dirname(__FILE__), '..', '..', 'test')) do
        `mkdir repositories` unless File.exists? 'repositories'
        Dir.chdir 'repositories' do
          `mkdir #{scm}repo`
          Dir.chdir("#{scm}repo") do
            `git init`
            open 'readme.txt', 'w' do |f|
              f.write "readme.txt Line 1
            Line 2
            Line 3"
            end

            `git add .`
            `git commit -m "added readme.txt"`

            open 'readme.txt', 'a' do |f|
              f.write "line 4"
            end

            `git add .`
            `git commit -m "added a line to readme.txt"`
          end
        end
      end
    end

    def initialize_test_svn_repository
      scm = 'svn'
      Dir.chdir(File.join(File.dirname(__FILE__), '..', '..', 'test')) do
        `mkdir repositories` unless File.exists? 'repositories'
        Dir.chdir 'repositories' do
          puts `svnadmin create #{scm}repo`
        end
      end
    end

    def destroy_test_repository scm
      puts(rmcmd = "rm -rf #{repository_dir(scm)}")
      puts `#{rmcmd}`
    end

    def repository_dir scm = nil
      if scm.nil?
        File.join(File.dirname(__FILE__), '..', '..', 'test', 'repositories')
      else
        File.expand_path(File.join(repository_dir, "#{scm}repo"))
      end
    end

    def create_test_modules_repository scm
      Dir.chdir(File.join(File.dirname(__FILE__), '..', '..', 'test')) do
        `mkdir repositories` unless File.exists? 'repositories'
        Dir.chdir 'repositories' do
          puts `svnadmin create #{scm}modulesrepo`
        end

        cmd = "svn checkout \"file:///#{File.expand_path(File.join('repositories', "#{scm}modulesrepo"))}\""
        puts "about to run #{cmd}"
        puts `#{cmd}`
        Dir.chdir "#{scm}modulesrepo" do
          if !File.exists? 'modules.txt'
            open("modules.txt", "w") do |f|
              f.write "line1 of modules.txt\n"
            end

            SvnProject.add_all
            puts `svn commit -m "created modules.txt"`
          end
        end
        `rm -rf #{scm}modulesrepo`
      end
    end

    def with_svn_branches_modules_repository_dir
      File.expand_path(File.join(repository_dir, with_svn_branches_modules_repository_name))
    end
    def with_svn_branches_modules_repository_url
      url = "file:///#{with_svn_branches_modules_repository_dir}"
      if windows?
        url.gsub!(/\\/, "/")
      end
      url.gsub("file:////", 'file:///')
    end
    def with_svn_branches_repository_url
      url = "file:///#{with_svn_branches_repository_dir}"
      if windows?
        url.gsub!(/\\/, "/")
      end
      url.gsub("file:////", 'file:///')
    end

    def with_svn_branches_modules_repository_name
      'svnmodulesbranchesrepo'
    end
    def with_svn_branches_repository_dir
      File.expand_path(File.join(repository_dir, with_svn_branches_repository_name))
    end
    def with_svn_branches_repository_name
      'svnbranchesrepo'
    end

    def destroy_with_svn_branches_modules_repository
      Dir.chdir repository_dir do
        `rm -rf #{with_svn_branches_modules_repository_name}`
      end
    end

    def destroy_with_svn_branches_repository
      Dir.chdir repository_dir do
        `rm -rf #{with_svn_branches_repository_name}`
      end
    end

    def create_with_svn_branches_modules_repository
      Dir.chdir(File.join(root_dir, 'test')) do
        `mkdir repositories` unless File.exists? 'repositories'
        Dir.chdir repository_dir do
          puts `svnadmin create #{with_svn_branches_modules_repository_name}`
        end

        `mkdir workdir` unless File.exists? 'workdir'
        Dir.chdir 'workdir' do
          cmd = "svn checkout \"#{with_svn_branches_modules_repository_url}\""
          puts "about to run #{cmd}"
          puts `#{cmd}`
          raise unless $? == 0

          Dir.chdir with_svn_branches_modules_repository_name do
            `mkdir branches`
            `mkdir current`

            SvnProject.add_all
            puts `svn commit -m "created branch directory structure"`
            raise unless $? == 0

          end
          `rm -rf #{with_svn_branches_modules_repository_name}`
        end
      end
    end
    def create_with_svn_branches_repository
      Dir.chdir(File.join(root_dir, 'test')) do
        `mkdir repositories` unless File.exists? 'repositories'
        Dir.chdir repository_dir do
          puts `svnadmin create #{with_svn_branches_repository_name}`
        end

        `mkdir workdir` unless File.exists? 'workdir'
        Dir.chdir 'workdir' do
          cmd = "svn checkout \"#{with_svn_branches_repository_url}\""
          puts "about to run #{cmd}"
          puts `#{cmd}`
          raise unless $? == 0

          Dir.chdir with_svn_branches_repository_name do
            `mkdir branches`
            `mkdir current`

            SvnProject.add_all
            puts `svn commit -m "created branch directory structure"`
            raise unless $? == 0

          end
          `rm -rf #{with_svn_branches_modules_repository_name}`
        end
      end
    end

    def destroy_test_modules_repository scm
      puts(rmcmd = "rm -rf #{modules_repository_dir(scm)}")
      puts `#{rmcmd}`
    end

    def modules_repository_dir scm = nil
      File.expand_path(File.join(repository_dir, "#{scm}modulesrepo"))
    end

    def create_rails_application
      Dir.mkdir applications_dir unless File.exists?(applications_dir)
      Dir.chdir applications_dir do
        if rails_version =~ /^3([^\d]|$)/
          puts `#{rails_exe} new rails_app`
        elsif rails_version =~ /^2([^\d]|$)/
          puts `#{rails_exe} rails_app`
        else
          raise "can't determine rails version"
        end
      end
    end

    def rails_version
      /[\d\.]+/.match(`#{rails_exe} --version`)[0]
    end

    def rails_exe
      "jruby -S rails"
      "rails"
    end

    def windows?
      ENV['OS'] =~ /^Win/i
    end

    def destroy_rails_application
      Dir.chdir applications_dir do
        `rm -rf rails_app`
      end
    end

    def root_dir
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    end

    def applications_dir
      File.join(root_dir, 'test', 'applications')
    end

    def rails_application_dir
      File.join(applications_dir, 'rails_app')
    end

    def initialize_with_svn_branches_repository
      Dir.chdir File.join(root_dir, 'test') do
        repo_url = with_svn_branches_repository_url

        Dir.chdir 'workdir' do
          puts `svn co #{[repo_url, "current"].join("/")} rails_app`
          raise unless $? == 0
          Dir.chdir "rails_app" do
            puts `cp -r #{rails_application_dir}/* .`
            raise unless $? == 0

            Ext.run "init", "-b", "current"

            # this line is necessary as ext can't perform the necessary
            # ignores otherwise if vendor and vendor/plugins haven't been added
            SvnProject.add_all

            raise " could not create .externals"  unless File.exists? '.externals'
            %w(rails acts_as_list).each do |proj|
              Ext.run "install", File.join(root_dir, 'test', 'cleanreps', "#{proj}.git")
            end

            #install a couple svn managed subprojects
            %w(foreign_key_migrations redhillonrails_core).each do |proj|
              Ext.run "install", "--svn", "file:///#{File.join(root_dir, 'test', 'cleanreps', proj)}"
            end

            #install project with a git branch
            Ext.run "install", File.join(root_dir, 'test', 'cleanreps', 'engines.git'), "-b", "edge"

            #install project with a non-default path and svn branching
            Ext.run "install", "--svn",
              "#{with_svn_branches_modules_repository_url}",
              "-b", "current",
              "modules"

            SvnProject.add_all

            puts `svn commit -m "created empty rails app with some subprojects"`
            raise unless $? == 0

            # now let's make a branch in the main project called new_branch
            `svn copy #{
            [repo_url, "current"].join("/")
} #{[repo_url, "branches", "new_branch"].join("/")} -m "creating branch" `
            raise unless $? == 0

            # let's make a branch in a git subproject:
            Dir.chdir File.join(%w(vendor plugins engines)) do
              `git push origin master:branch1`
              raise unless $? == 0
            end

            # let's update the .externals file in new_branch to reflect these changes
            `svn switch #{[repo_url, "branches", "new_branch"].join("/")}`
            raise unless $? == 0

            # let's remove rails from this branch
            Ext.run "uninstall", "-f", "rails"

            ext = Ext.new
            ext.configuration["vendor/plugins/engines"]["branch"] = "branch1"
            ext.configuration["modules"]["branch"] = "branches/branch2"
            ext.configuration.write

            SvnProject.add_all
            `svn commit -m "updated .externals to point to new branches."`
            raise unless $? == 0
          end

          `rm -rf rails_app`
        end
      end
    end

    def initialize_with_svn_branches_modules_repository
      Dir.chdir File.join(root_dir, 'test') do
        repo_url = with_svn_branches_modules_repository_url

        Dir.chdir 'workdir' do
          puts `svn co #{[repo_url, "current"].join("/")} modules`
          raise unless $? == 0
          Dir.chdir "modules" do
            if !File.exists? 'modules.txt'
              open("modules.txt", "w") do |f|
                f.write "line1 of modules.txt\n"
              end

              SvnProject.add_all
              puts `svn commit -m "created modules.txt"`
              raise unless $? == 0
            end

            `svn copy #{
            [repo_url, "current"].join("/")
} #{[repo_url, "branches", "branch2"].join("/")
} -m "created branch2"`
            raise unless $? == 0

            puts `svn switch #{
            [repo_url, "branches", "branch2"].join("/")
}`
            raise unless $? == 0
            `echo 'line 2 of modules.txt ... this is branch2!' > modules.txt`
            SvnProject.add_all
            puts `svn commit -m "changed modules.txt"`
            raise unless $? == 0
          end
        end
      end
    end

  end
end