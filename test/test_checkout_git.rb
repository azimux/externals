$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestCheckoutGit < TestCase
    def setup
      initialize_test_git_repository

      Dir.chdir File.join(root_dir, 'test') do
        `rm -rf workdir`
      end
    end

    def teardown
      destroy_test_repository 'git'
    end
   
    def test_repository_created
      assert File.exists?(File.join(repository_dir('git'), '.git'))
    end
    
    def test_checkout
      Dir.chdir File.join(root_dir, 'test') do
        `mkdir workdir`
      
        Dir.chdir 'workdir' do
          puts "Currently in #{Dir.pwd}"
          Ext.run "checkout", "--git", repository_dir('git')
        
          assert File.exists?(File.join(repository_dir('git'),'.git'))
        end
      end
    end
  end
end