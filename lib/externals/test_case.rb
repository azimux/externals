require 'test/unit'

module Externals
  class TestCase <  Test::Unit::TestCase
    protected
    
    def initialize_test_git_repository
      scm = 'git'
      Dir.chdir(File.join(File.dirname(__FILE__), '..', '..', 'test','repositories')) do
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
    def initialize_test_svn_repository
      scm = 'svn'
      Dir.chdir(File.join(File.dirname(__FILE__), '..', '..', 'test','repositories')) do
        puts `svnadmin create #{scm}repo`
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
    
    
    def create_rails_application
      Dir.mkdir applications_dir unless File.exists?(applications_dir)
      Dir.chdir applications_dir do
        puts `rails rails_app`
      end
    end
    
    def rails_bin_prefix
      "C:\\ruby\\bin\\" if windows?
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
    
    public
    def test_true
      assert true
    end
  end
end