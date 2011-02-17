require 'test/unit'

module Externals
  TestCase = Test::Unit::TestCase
  module ExtTestCase
    protected

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

    def destroy_test_modules_repository scm
      puts(rmcmd = "rm -rf #{modules_repository_dir(scm)}")
      puts `#{rmcmd}`
      puts(rmcmd = "rm -rf #{modules_repository_dir(scm)}")
      puts `#{rmcmd}`
    end

    def modules_repository_dir scm = nil
      if scm.nil?
        File.join(File.dirname(__FILE__), '..', '..', 'test', 'repositories')
      else
        File.expand_path(File.join(repository_dir, "#{scm}modulesrepo"))
      end
    end


    def create_rails_application
      Dir.mkdir applications_dir unless File.exists?(applications_dir)
      Dir.chdir applications_dir do
        if rails_version =~ /^3([^\d]|$)/
          puts `rails new rails_app`
        elsif rails_version =~ /^2([^\d]|$)/
          puts `rails rails_app`
        else
          raise "can't determine rails version"
        end
      end
    end

    def rails_version
      /[\d\.]+/.match(`rails --version`)[0]
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
  end
end